import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../enums.dart';
import '../zpl_configuration.dart';
import '../zpl_graphic_symbol.dart';
import '../zpl_text.dart';
import '../zpl_text_block.dart';

/// Font family bundled with the package to stand in for Zebra's scalable
/// font 0 (CG Triumvirate Bold Condensed). Archivo Narrow is an
/// open-licensed grotesque condensed face with similar proportions.
const String zplPreviewFontFamily = 'ArchivoNarrow';
const String zplPreviewFontPackage = 'flutter_zpl_generator';

/// Cap height of Archivo Narrow as a fraction of the em (OS/2 sCapHeight).
const double _fontCapHeight = 0.686;

/// Zebra font 0: measured on Labelary, capital letters ink at 75 % of the
/// `^A0` height parameter with the cap top exactly on the field origin.
const double _zplCapRatio = 0.75;

/// Horizontal calibration: with width == height, "Hello World" prints
/// 4.625 x height wide on Labelary and "CENTERED" 4.23 x height; Archivo
/// Narrow Bold at the cap-matched size is 4.98 x and 4.67 x. This factor
/// splits the difference (mixed case ~4 % narrow, capitals ~4 % wide).
const double _zplWidthCalibration = 0.91;

/// Point size that makes the font's cap height equal Zebra's.
double previewFontSize(double zplHeight) =>
    zplHeight * _zplCapRatio / _fontCapHeight;

/// Horizontal scale for a ZPL width/height pair.
double previewHorizontalScale(double zplWidth, double zplHeight) =>
    (zplWidth / zplHeight) * _zplWidthCalibration;

TextStyle previewTextStyle(
  double zplHeight, {
  Paint? foreground,
  double? lineHeight,
}) => TextStyle(
  fontFamily: zplPreviewFontFamily,
  package: zplPreviewFontPackage,
  fontVariations: const [FontVariation('wght', 700)],
  fontSize: previewFontSize(zplHeight),
  height: lineHeight,
  color: foreground == null ? Colors.black : null,
  foreground: foreground,
);

/// Vertical offset so the first line's cap top lands on the field origin.
double _capTopOffset(TextPainter tp) {
  final metrics = tp.computeLineMetrics();
  if (metrics.isEmpty) return 0;
  final size = tp.text!.style!.fontSize!;
  return metrics.first.baseline - _fontCapHeight * size;
}

/// Draws a [ZplText] the way `^A0`/`^FB` lay it out.
void drawZplText(Canvas canvas, ZplText text, ZplConfiguration config) {
  final fh = (text.fontHeight ?? 20).toDouble();
  // Zebra font 0 defaults the width to the height (measured: ^A0N,40 and
  // ^A0N,40,40 render identically).
  final fw = (text.fontWidth ?? text.fontHeight ?? 20).toDouble();
  final hScale = previewHorizontalScale(fw, fh);
  final fontSize = previewFontSize(fh);
  // ^FB line spacing is added between lines in dots; express as a
  // multiplier of the font size.
  final lineHeight = text.maxLines > 1
      ? (fh + text.lineSpacing) / fontSize
      : null;

  final foreground = Paint()
    ..color = text.reversePrint ? Colors.white : Colors.black
    ..blendMode = text.reversePrint ? BlendMode.difference : BlendMode.srcOver;

  final tp = TextPainter(
    text: TextSpan(
      text: text.text,
      style: previewTextStyle(
        fh,
        foreground: foreground,
        lineHeight: lineHeight,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: text.maxLines > 1 ? text.maxLines : 1,
    // ZplText.toZpl only justifies the ^FB block when the text is in a
    // container (maxWidth) or starts at x == 0; otherwise it emits `L`.
    textAlign: text.maxWidth == null && text.x != 0
        ? TextAlign.left
        : switch (text.alignment) {
            ZplAlignment.center => TextAlign.center,
            ZplAlignment.right => TextAlign.right,
            _ => TextAlign.left,
          },
  );

  // Mirror ZplText.toZpl: a ^FB block is emitted when aligned or wrapping.
  final labelWidth = (text.maxWidth ?? config.printWidth ?? 406).toDouble();
  final aligned = text.alignment != null && text.alignment != ZplAlignment.left;
  double originX = text.x.toDouble();
  double? blockWidth;
  if (aligned && text.maxWidth != null) {
    blockWidth = labelWidth - text.paddingLeft - text.paddingRight;
  } else if (aligned && text.x == 0) {
    blockWidth = labelWidth - text.paddingLeft - text.paddingRight;
    originX = 0;
  } else if (text.maxLines > 1) {
    // Mirrors ZplText._wrapWidth: a container slot (maxWidth) already
    // starts at x, so only the label width is measured from the origin.
    blockWidth = text.maxWidth != null
        ? (text.maxWidth! - text.paddingRight).toDouble()
        : labelWidth - text.x - text.paddingRight;
  }

  if (blockWidth != null) {
    final w = blockWidth / hScale;
    tp.layout(minWidth: w, maxWidth: w);
  } else {
    tp.layout();
  }

  canvas.save();
  // Zebra's rotated bounding box is (text width) x (^A height): the cap
  // top sits on the box's top edge and the box is one font height tall.
  applyFieldOrientation(
    canvas,
    text.orientation,
    originX,
    text.y.toDouble(),
    tp.width * hScale,
    fh,
  );
  canvas.translate(0, -_capTopOffset(tp));
  canvas.scale(hScale, 1.0);
  tp.paint(canvas, Offset.zero);
  canvas.restore();
}

/// Positions the canvas so that a field of [width] x [height] dots drawn at
/// the local origin appears rotated per [orientation] with `^FO` ([x], [y])
/// as the top-left corner of the rotated bounding box, as Zebra does.
void applyFieldOrientation(
  Canvas canvas,
  ZplOrientation orientation,
  double x,
  double y,
  double width,
  double height,
) {
  switch (orientation) {
    case ZplOrientation.normal:
      canvas.translate(x, y);
    case ZplOrientation.rotated90:
      canvas.translate(x + height, y);
      canvas.rotate(math.pi / 2);
    case ZplOrientation.inverted180:
      canvas.translate(x + width, y + height);
      canvas.rotate(math.pi);
    case ZplOrientation.readFromBottomUp270:
      canvas.translate(x, y + width);
      canvas.rotate(-math.pi / 2);
  }
}

/// Draws a `^GS` graphic symbol. ® and © come from the preview font; the
/// UL / CSA / VDE certification marks are not glyphs, so they are drawn as
/// a ringed abbreviation of the same size.
void drawZplGraphicSymbol(Canvas canvas, ZplGraphicSymbol symbol) {
  final h = symbol.height.toDouble(), w = symbol.width.toDouble();
  final (glyph, ringed) = switch (symbol.symbol) {
    ZplGraphicSymbolType.registeredTrademark => ('®', false),
    ZplGraphicSymbolType.copyright => ('©', false),
    ZplGraphicSymbolType.ul => ('UL', true),
    ZplGraphicSymbolType.csa => ('CSA', true),
    ZplGraphicSymbolType.vde => ('VDE', true),
  };
  canvas.save();
  canvas.translate(symbol.x.toDouble(), symbol.y.toDouble());
  if (ringed) {
    canvas.drawOval(
      Rect.fromLTWH(1, 1, w - 2, h - 2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (h / 12).clamp(1, 6)
        ..color = Colors.black,
    );
  }
  final size = ringed ? h * 0.36 : h;
  final tp = TextPainter(
    text: TextSpan(text: glyph, style: previewTextStyle(size)),
    textDirection: TextDirection.ltr,
  )..layout();
  final sx = ringed ? (w * 0.8) / tp.width : w / tp.width;
  canvas.translate((w - tp.width * sx) / 2, (h - tp.height) / 2);
  canvas.scale(sx, 1.0);
  tp.paint(canvas, Offset.zero);
  canvas.restore();
}

/// Draws a [ZplTextBlock] (`^TB`): wrapped text inside a fixed box using the
/// last `^A` font, which the block does not carry, so a 24-dot font 0 is
/// assumed.
void drawZplTextBlock(Canvas canvas, ZplTextBlock block) {
  const fh = 24.0;
  final hScale = previewHorizontalScale(fh, fh);
  final tp = TextPainter(
    text: TextSpan(text: block.text, style: previewTextStyle(fh)),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: block.maxWidth / hScale);
  canvas.save();
  canvas.translate(block.x.toDouble(), block.y.toDouble() - _capTopOffset(tp));
  canvas.scale(hScale, 1.0);
  canvas.clipRect(
    Rect.fromLTWH(0, 0, block.maxWidth / hScale, block.maxHeight.toDouble()),
  );
  tp.paint(canvas, Offset.zero);
  canvas.restore();
}
