// Fidelity harness: renders the same label through ZplCanvasPainter and
// through Labelary at 8 dpmm, then compares the two bitmaps.
//
// Skipped by default (network). Run with:
//   FIDELITY_OUT=/tmp/fidelity fvm flutter test \
//     --dart-define=SKIP_INTEGRATION_TESTS=false \
//     test/native_preview_fidelity_harness_test.dart
//
// Writes <case>.png (labelary | painter | diff) into FIDELITY_OUT and prints
// a metrics table. Diff colours: red = painter only, blue = Labelary only.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/src/preview/zpl_canvas_painter.dart';
import 'package:image/image.dart' as img;

const _skip = bool.fromEnvironment(
  'SKIP_INTEGRATION_TESTS',
  defaultValue: true,
);

typedef _Case = ({String name, ZplGenerator gen});

const _cfg = ZplConfiguration(
  printWidth: 406,
  labelLength: 203,
  printDensity: ZplPrintDensity.d8,
);

List<_Case> _cases() => [
  (
    name: 'text_a0_40x40',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplText(
          x: 20,
          y: 20,
          text: 'Hello World',
          fontHeight: 40,
          fontWidth: 40,
        ),
      ],
    ),
  ),
  (
    name: 'text_a0_40_default_width',
    gen: ZplGenerator(
      config: _cfg,
      commands: [ZplText(x: 20, y: 20, text: 'Hello World', fontHeight: 40)],
    ),
  ),
  (
    name: 'text_a0_60x30_condensed',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplText(
          x: 20,
          y: 20,
          text: 'Receipt Total',
          fontHeight: 60,
          fontWidth: 30,
        ),
      ],
    ),
  ),
  (
    name: 'text_center_aligned',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplText(
          y: 40,
          text: 'CENTERED',
          fontHeight: 30,
          fontWidth: 30,
          alignment: ZplAlignment.center,
        ),
      ],
    ),
  ),
  (
    name: 'barcode_code128',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplBarcode(
          x: 20,
          y: 20,
          data: 'ABC-12345',
          height: 100,
          moduleWidth: 2,
        ),
      ],
    ),
  ),
  (
    name: 'barcode_code39',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplBarcode(
          x: 20,
          y: 20,
          data: 'CODE39',
          type: ZplBarcodeType.code39,
          height: 100,
          moduleWidth: 2,
        ),
      ],
    ),
  ),
  (
    name: 'barcode_ean13',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplBarcode(
          x: 20,
          y: 20,
          data: '5901234123457',
          type: ZplBarcodeType.ean13,
          height: 100,
          moduleWidth: 3,
        ),
      ],
    ),
  ),
  (
    name: 'barcode_qr_mag3',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplBarcode(
          x: 20,
          y: 20,
          data: 'https://pub.dev/packages/flutter_zpl_generator',
          type: ZplBarcodeType.qrCode,
          height: 0,
        ),
      ],
    ),
  ),
  (
    name: 'barcode_qr_short_alnum',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplBarcode(
          x: 20,
          y: 20,
          data: 'HELLO WORLD 12345',
          type: ZplBarcodeType.qrCode,
          height: 0,
          magnification: 4,
        ),
      ],
    ),
  ),
  (
    name: 'barcode_qr_high_ecc',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplBarcode(
          x: 20,
          y: 20,
          data: 'https://pub.dev/packages/flutter_zpl_generator',
          type: ZplBarcodeType.qrCode,
          height: 0,
          qrErrorCorrection: ZplQrErrorCorrection.high,
        ),
      ],
    ),
  ),
  (
    name: 'barcode_code128_with_text_digits',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplBarcode(
          x: 20,
          y: 20,
          data: 'SN2026091234',
          height: 80,
          moduleWidth: 2,
        ),
      ],
    ),
  ),
  (
    name: 'barcode_center_aligned',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplBarcode(
          y: 30,
          data: '12345',
          height: 60,
          alignment: ZplAlignment.center,
          printInterpretationLine: false,
        ),
      ],
    ),
  ),
  (
    name: 'text_rotated_90',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplText(
          x: 60,
          y: 20,
          text: 'ROTATED',
          fontHeight: 30,
          fontWidth: 30,
          orientation: ZplOrientation.rotated90,
        ),
      ],
    ),
  ),
  (
    name: 'text_rotated_270',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplText(
          x: 60,
          y: 180,
          text: 'BOTTOM UP',
          fontHeight: 30,
          fontWidth: 30,
          orientation: ZplOrientation.readFromBottomUp270,
        ),
      ],
    ),
  ),
  (
    name: 'text_inverted_180',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplText(
          x: 200,
          y: 80,
          text: 'FLIPPED',
          fontHeight: 30,
          fontWidth: 30,
          orientation: ZplOrientation.inverted180,
        ),
      ],
    ),
  ),
  (
    name: 'text_multiline_wrap',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplText(
          x: 20,
          y: 20,
          text: 'The quick brown fox jumps over the lazy dog again and again',
          fontHeight: 28,
          fontWidth: 28,
          maxLines: 3,
          maxWidth: 300,
        ),
      ],
    ),
  ),
  (
    name: 'conditional_and_symbol',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplConditional(
          condition: true,
          child: ZplBox(
            x: 20,
            y: 20,
            width: 100,
            height: 60,
            borderThickness: 3,
          ),
        ),
        ZplConditional(
          condition: false,
          child: ZplBox(
            x: 200,
            y: 20,
            width: 100,
            height: 60,
            borderThickness: 3,
          ),
        ),
      ],
    ),
  ),
  (
    name: 'barcode_datamatrix',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplBarcode(
          x: 20,
          y: 20,
          data: 'DM-SAMPLE-2024',
          type: ZplBarcodeType.dataMatrix,
          height: 6,
        ),
      ],
    ),
  ),
  (
    name: 'box_and_circle',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplBox(x: 20, y: 20, width: 200, height: 100, borderThickness: 4),
        ZplBox(x: 240, y: 20, width: 60, height: 60, borderThickness: 60),
        ZplGraphicCircle(x: 320, y: 20, diameter: 80, borderThickness: 3),
      ],
    ),
  ),
  (
    name: 'grid_row_three_cols',
    gen: ZplGenerator(
      config: _cfg,
      commands: [
        ZplGridRow(
          y: 20,
          children: [
            ZplGridCol(width: 4, child: ZplText(text: 'Left', fontHeight: 30)),
            ZplGridCol(
              width: 4,
              child: ZplText(
                text: 'Mid',
                fontHeight: 30,
                alignment: ZplAlignment.center,
              ),
            ),
            ZplGridCol(
              width: 4,
              child: ZplText(
                text: 'Right',
                fontHeight: 30,
                alignment: ZplAlignment.right,
              ),
            ),
          ],
        ),
        ZplSeparator(y: 70, thickness: 2),
        ZplBarcode(
          y: 90,
          data: '12345',
          height: 60,
          alignment: ZplAlignment.center,
          printInterpretationLine: false,
        ),
      ],
    ),
  ),
];

/// Binarised bitmap: true = black.
class _Bits {
  final int w, h;
  final List<bool> px;
  _Bits(this.w, this.h, this.px);

  bool at(int x, int y) => px[y * w + x];

  ({int l, int t, int r, int b})? bbox() {
    int l = w, t = h, r = -1, b = -1;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (at(x, y)) {
          if (x < l) l = x;
          if (x > r) r = x;
          if (y < t) t = y;
          if (y > b) b = y;
        }
      }
    }
    return r < 0 ? null : (l: l, t: t, r: r, b: b);
  }
}

_Bits _fromImage(img.Image im, int w, int h) {
  final px = List<bool>.filled(w * h, false);
  for (int y = 0; y < h && y < im.height; y++) {
    for (int x = 0; x < w && x < im.width; x++) {
      final p = im.getPixel(x, y);
      // Labelary PNGs are 8-bit grayscale: a single channel, so read `r`.
      final v = im.numChannels == 1 ? p.r : p.luminance;
      px[y * w + x] = v < 128;
    }
  }
  return _Bits(w, h, px);
}

Future<_Bits> _paint(ZplGenerator gen, int w, int h) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    Paint()..color = Colors.white,
  );
  ZplCanvasPainter(
    generator: gen,
  ).paint(canvas, Size(w.toDouble(), h.toDouble()));
  final image = await rec.endRecording().toImage(w, h);
  final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final px = List<bool>.filled(w * h, false);
  for (int i = 0; i < w * h; i++) {
    final r = bytes.getUint8(i * 4),
        g = bytes.getUint8(i * 4 + 1),
        b = bytes.getUint8(i * 4 + 2);
    px[i] = (0.299 * r + 0.587 * g + 0.114 * b) < 128;
  }
  return _Bits(w, h, px);
}

Future<_Bits> _labelary(ZplGenerator gen, int w, int h) async {
  final zpl = await gen.build();
  final res = await LabelaryService.renderZpl(
    zpl,
    width: w / 203,
    height: h / 203,
  );
  final im = img.decodePng(res.data)!;
  return _fromImage(im, w, h);
}

img.Image _sideBySide(_Bits a, _Bits b) {
  final w = a.w, h = a.h, gap = 8;
  final out = img.Image(width: w * 3 + gap * 2, height: h);
  img.fill(out, color: img.ColorRgb8(255, 255, 255));
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final la = a.at(x, y), pa = b.at(x, y);
      if (la) out.setPixelRgb(x, y, 0, 0, 0);
      if (pa) out.setPixelRgb(x + w + gap, y, 0, 0, 0);
      final dx = x + 2 * (w + gap);
      if (la && pa) {
        out.setPixelRgb(dx, y, 0, 0, 0);
      } else if (pa) {
        out.setPixelRgb(dx, y, 220, 0, 0);
      } else if (la) {
        out.setPixelRgb(dx, y, 0, 0, 220);
      }
    }
  }
  return out;
}

/// Minimum acceptable overlap per case. Text and QR are glyph/mask-limited
/// (different typeface; Zebra's QR mask choice is not reproducible), so
/// their gate is the bounding box, checked separately below.
const _minIou = <String, double>{
  'barcode_code128': 0.90,
  'barcode_code39': 0.90,
  'barcode_ean13': 0.85,
  'barcode_code128_with_text_digits': 0.90,
  'barcode_center_aligned': 0.99,
  'barcode_qr_short_alnum': 0.99,
  'barcode_datamatrix': 0.99,
  'box_and_circle': 0.99,
  'conditional_and_symbol': 0.99,
};

/// Maximum bounding-box drift for every case: 6 dots, or 8 % of the larger
/// Labelary dimension for big fields (text width scales with the glyph
/// shapes of the substitute font).
int _maxBboxDrift(({int l, int t, int r, int b}) lb) {
  final size = [
    lb.r - lb.l + 1,
    lb.b - lb.t + 1,
  ].reduce((a, b) => a > b ? a : b);
  return [6, (size * 0.08).ceil()].reduce((a, b) => a > b ? a : b);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null; // restore real networking under flutter_test

  test(
    'native preview vs Labelary fidelity',
    () async {
      final outDir =
          Platform.environment['FIDELITY_OUT'] ?? Directory.systemTemp.path;
      Directory(outDir).createSync(recursive: true);
      // flutter_test does not load package fonts declared in pubspec for
      // plain test() bodies; register the preview font explicitly.
      final fontFile = File('fonts/archivo-narrow-variable.ttf');
      final loader = FontLoader('packages/flutter_zpl_generator/ArchivoNarrow')
        ..addFont(
          Future.value(ByteData.view(fontFile.readAsBytesSync().buffer)),
        );
      await loader.load();

      final w = _cfg.printWidth!, h = _cfg.labelLength!;
      final rows = <String>[];
      final panels = <(String, img.Image)>[];
      final failures = <String>[];
      for (final c in _cases()) {
        final lab = await _labelary(c.gen, w, h);
        final pnt = await _paint(c.gen, w, h);
        int both = 0, either = 0;
        for (int i = 0; i < w * h; i++) {
          final l = lab.px[i], p = pnt.px[i];
          if (l && p) both++;
          if (l || p) either++;
        }
        final iou = either == 0 ? 1.0 : both / either;
        final lb = lab.bbox(), pb = pnt.bbox();
        String box(({int l, int t, int r, int b})? b) => b == null
            ? 'none'
            : '${b.l},${b.t} ${b.r - b.l + 1}x${b.b - b.t + 1}';
        rows.add(
          '${c.name.padRight(34)} IoU ${(iou * 100).toStringAsFixed(1).padLeft(5)}%  '
          'labelary[${box(lb)}]  painter[${box(pb)}]',
        );
        final panel = _sideBySide(lab, pnt);
        File('$outDir/${c.name}.png').writeAsBytesSync(img.encodePng(panel));
        panels.add((c.name, panel));

        final minIou = _minIou[c.name];
        if (minIou != null && iou < minIou) {
          failures.add(
            '${c.name}: IoU ${(iou * 100).toStringAsFixed(1)}% < ${(minIou * 100).toStringAsFixed(0)}%',
          );
        }
        if (lb != null && pb != null) {
          final drift = [
            (lb.l - pb.l).abs(),
            (lb.t - pb.t).abs(),
            (lb.r - pb.r).abs(),
            (lb.b - pb.b).abs(),
          ].reduce((a, b) => a > b ? a : b);
          final limit = _maxBboxDrift(lb);
          if (drift > limit) {
            failures.add('${c.name}: bbox drift $drift dots > $limit');
          }
        } else if ((lb == null) != (pb == null)) {
          failures.add('${c.name}: one side rendered nothing');
        }
      }

      // One tall grid: label | painter | diff per row, for eyeballing.
      const labelH = 18;
      final rowH = h + labelH;
      final grid = img.Image(
        width: panels.first.$2.width,
        height: rowH * panels.length,
      );
      img.fill(grid, color: img.ColorRgb8(255, 255, 255));
      for (int i = 0; i < panels.length; i++) {
        img.drawString(
          grid,
          '${panels[i].$1}   (Labelary | native preview | diff: red=preview only, blue=Labelary only)',
          font: img.arial14,
          x: 4,
          y: i * rowH + 2,
          color: img.ColorRgb8(0, 0, 0),
        );
        img.compositeImage(
          grid,
          panels[i].$2,
          dstX: 0,
          dstY: i * rowH + labelH,
        );
      }
      File('$outDir/fidelity-grid.png').writeAsBytesSync(img.encodePng(grid));

      // ignore: avoid_print
      print(
        '\nFIDELITY (IoU of black pixels; bbox = x,y wxh in dots)\n${rows.join('\n')}\n'
        'grid: $outDir/fidelity-grid.png\n',
      );
      expect(failures, isEmpty, reason: failures.join('\n'));
    },
    skip: _skip,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
