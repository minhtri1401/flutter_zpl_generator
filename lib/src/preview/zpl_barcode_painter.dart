import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';

import '../enums.dart';
import '../zpl_barcode.dart';
import '../zpl_configuration.dart';
import 'zpl_barcode_preview_mapping.dart';
import 'zpl_barcode_symbol_metrics.dart';
import 'zpl_text_painter.dart';

/// Draws a [ZplBarcode] on [canvas] at printer-dot scale, sized from the
/// real encoded module count so it matches what Zebra firmware prints:
/// no quiet zones, bars at the full `^BY` width and height, interpretation
/// line added below (or above) the bars rather than carved out of them.
void drawZplBarcode(Canvas canvas, ZplBarcode b, ZplConfiguration config) {
  final x = b.getAlignedX(config).toDouble();
  final y = b.y.toDouble();
  final m = measureBarcodeSymbol(b);
  if (m == null) {
    _drawError(canvas, x, y, 'Unencodable ${b.type.name}: ${b.data}');
    return;
  }

  final paint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill
    ..isAntiAlias = false;

  final is1D = !isTwoDimensional(b.type);
  final textH = is1D && b.printInterpretationLine
      ? interpretationLineHeight(b)
      : 0.0;
  final fieldH = m.height + textH + symbolTopOffset(b);

  // Rotate the whole field (symbol + interpretation line) about ^FO the
  // way Zebra does, then draw at the local origin.
  canvas.save();
  applyFieldOrientation(canvas, b.orientation, x, y, m.width, fieldH);
  if (m.qrIsDark != null) {
    _drawQr(canvas, paint, m, 0, symbolTopOffset(b));
  } else if (!is1D) {
    _draw2D(canvas, paint, b, m, 0, 0);
  } else {
    _draw1D(canvas, paint, b, m, 0, 0);
  }
  canvas.restore();
}

void _drawQr(
  Canvas canvas,
  Paint paint,
  ZplBarcodeSymbolMetrics m,
  double x,
  double y,
) {
  final n = m.modulesHigh, s = m.moduleWidth;
  for (int r = 0; r < n; r++) {
    for (int c = 0; c < n; c++) {
      if (m.qrIsDark!(r, c)) {
        canvas.drawRect(Rect.fromLTWH(x + c * s, y + r * s, s, s), paint);
      }
    }
  }
}

void _draw2D(
  Canvas canvas,
  Paint paint,
  ZplBarcode b,
  ZplBarcodeSymbolMetrics m,
  double x,
  double y,
) {
  final bars = previewBarcodeFor(b)
      .make(b.data, width: m.width, height: m.height)
      .whereType<BarcodeBar>()
      .toList();
  if (bars.isEmpty) return;
  // package:barcode may pick a different row/column split than the ^B7
  // parameters (and centre the result); stretch its output to the printed
  // box so size and position match even when the pattern cannot.
  double minL = double.infinity, minT = double.infinity;
  double maxR = 0, maxB = 0;
  for (final el in bars) {
    if (el.left < minL) minL = el.left;
    if (el.top < minT) minT = el.top;
    if (el.left + el.width > maxR) maxR = el.left + el.width;
    if (el.top + el.height > maxB) maxB = el.top + el.height;
  }
  final sx = maxR > minL ? m.width / (maxR - minL) : 1.0;
  final sy = maxB > minT ? m.height / (maxB - minT) : 1.0;
  for (final el in bars) {
    if (!el.black) continue;
    canvas.drawRect(
      Rect.fromLTWH(
        x + (el.left - minL) * sx,
        y + (el.top - minT) * sy,
        el.width * sx,
        el.height * sy,
      ),
      paint,
    );
  }
}

void _draw1D(
  Canvas canvas,
  Paint paint,
  ZplBarcode b,
  ZplBarcodeSymbolMetrics m,
  double x,
  double y,
) {
  final drawText = b.printInterpretationLine;
  final textH = drawText ? interpretationLineHeight(b) : 0.0;
  final barsTop = y + (b.printInterpretationLineAbove ? textH : 0.0);
  final mw = m.moduleWidth;

  // A second pass with text gives per-bar heights (EAN/UPC guard bars
  // extend into the text line) and the digit positions. Its bars carry
  // package margins, so map them onto the exact module grid by index.
  final textPass = drawText
      ? previewBarcodeFor(b)
            .make(
              b.data,
              width: m.width,
              height: m.height + textH,
              drawText: true,
              fontHeight: textH,
              textPadding: 0,
            )
            .toList()
      : const <BarcodeElement>[];
  final textBars = textPass.whereType<BarcodeBar>().toList();
  final sameCount = textBars.length == m.barUnits.length;

  double cursor = 0;
  for (int i = 0; i < m.barUnits.length; i++) {
    final w = m.barUnits[i] * mw;
    final black = sameCount ? textBars[i].black : i.isEven;
    final h = sameCount ? textBars[i].height : m.height;
    if (black) {
      canvas.drawRect(Rect.fromLTWH(x + cursor, barsTop, w, h), paint);
    }
    cursor += w;
  }

  if (!drawText || textBars.isEmpty) return;
  final srcLeft = textBars.first.left;
  final srcSpan = textBars.last.left + textBars.last.width - srcLeft;
  final scale = srcSpan > 0 ? m.width / srcSpan : 1.0;
  final texts = textPass.whereType<BarcodeText>().toList();

  // EAN/UPC print digit groups under their bar groups; every other
  // symbology prints the data as one centred word (package:barcode spreads
  // Code 39 / I2of5 characters across the width, Zebra does not).
  final retail = switch (b.type) {
    ZplBarcodeType.ean13 ||
    ZplBarcodeType.ean8 ||
    ZplBarcodeType.upcA ||
    ZplBarcodeType.upcE => true,
    _ => false,
  };
  final placements = retail
      ? [
          // Zebra omits EAN-13's leading digit (Labelary: ink starts at ^FO
          // x) but prints UPC-A/UPC-E system and check digits outside the
          // bars (ink starts ~20 dots left of x).
          for (final el in texts)
            if (b.type != ZplBarcodeType.ean13 || el.left >= srcLeft)
              (
                text: el.text,
                left: (el.left - srcLeft) * scale,
                width: el.width * scale,
                top: el.top,
                height: el.height,
              ),
        ]
      : [
          (
            // package:barcode strips the "(AI)" parentheses from GS1-128
            // text; Zebra prints the data as typed.
            text: b.type == ZplBarcodeType.gs1_128
                ? b.data
                : texts.map((e) => e.text).join(),
            left: 0.0,
            width: m.width,
            top: texts.first.top,
            height: texts.first.height,
          ),
        ];

  for (final el in placements) {
    final tp = TextPainter(
      text: TextSpan(
        text: el.text,
        style: previewTextStyle(textH * 0.8, lineHeight: 1.0),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(minWidth: el.width, maxWidth: el.width);
    final top = b.printInterpretationLineAbove
        ? y
        : barsTop + el.top + (el.height - tp.height) / 2;
    tp.paint(canvas, Offset(x + el.left, top));
  }
}

/// Height in dots of the human-readable line Zebra prints under 1D codes.
/// Measured on Labelary at 8 dpmm: 13/20/27/35 dots for module widths
/// 1–4, i.e. 7 dots per module plus 6.
double interpretationLineHeight(ZplBarcode b) => 7.0 * (b.moduleWidth ?? 2) + 6;

/// Vertical gap Zebra inserts between `^FO` and the first row of a symbol.
/// QR codes start 10 dots down regardless of magnification; other
/// symbologies start at the origin.
double symbolTopOffset(ZplBarcode b) =>
    b.type == ZplBarcodeType.qrCode ? 10.0 : 0.0;

void _drawError(Canvas canvas, double x, double y, String message) {
  canvas.drawRect(
    Rect.fromLTWH(x, y, 100, 50),
    Paint()..color = const Color(0x809E9E9E),
  );
  final tp = TextPainter(
    text: TextSpan(
      text: message,
      style: const TextStyle(color: Colors.black, fontSize: 12),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, Offset(x, y));
}
