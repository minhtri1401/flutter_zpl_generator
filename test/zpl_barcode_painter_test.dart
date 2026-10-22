import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/src/preview/zpl_barcode_painter.dart';
import 'package:flutter_zpl_generator/src/preview/zpl_barcode_symbol_metrics.dart';

/// Paints [b] at the origin of a [size] x [size] canvas and returns the
/// rasterised picture as RGBA bytes.
Future<ui.Image> _rasterise(ZplBarcode b, double size) async {
  final recorder = ui.PictureRecorder();
  drawZplBarcode(
    Canvas(recorder, Rect.fromLTWH(0, 0, size, size)),
    b,
    const ZplConfiguration(),
  );
  return recorder.endRecording().toImage(size.toInt(), size.toInt());
}

void main() {
  testWidgets('GS1 Data Matrix paints a module grid of the encoded size', (
    tester,
  ) async {
    final b = ZplBarcode(
      data: '(01)09501101530003(10)AB12',
      type: ZplBarcodeType.dataMatrix,
      height: 6,
      gs1: true,
    );
    final m = measureBarcodeSymbol(b)!;
    expect(m.modulesWide, m.modulesHigh);
    expect(m.width, m.height);

    await tester.runAsync(() async {
      final image = await _rasterise(b, 400);
      final rgba = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final w = image.width;
      var inked = 0, minX = w, minY = w, maxX = -1, maxY = -1;
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < w; x++) {
          if (rgba.getUint8((y * w + x) * 4 + 3) == 0) continue;
          inked++;
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
      expect(inked, greaterThan(0));
      // The painted box is the symbol at ^BX module height, from the origin.
      expect(maxX - minX + 1, closeTo(m.width, 1));
      expect(maxY - minY + 1, closeTo(m.height, 1));
      expect(minX, 0);
      expect(minY, 0);
    });
  });

  Future<List<int>> inkBox(ui.Image image) async {
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final w = image.width;
    var minX = w, minY = image.height, maxX = -1, maxY = -1;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < w; x++) {
        if (rgba.getUint8((y * w + x) * 4 + 3) == 0) continue;
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
    return [minX, minY, maxX, maxY];
  }

  testWidgets('token barcode data paints a placeholder inside its bounds', (
    tester,
  ) async {
    final b = ZplBarcode(
      data: '{{ean}}',
      type: ZplBarcodeType.ean13,
      height: 60,
      moduleWidth: 2,
    );
    expect(measureBarcodeSymbol(b), isNull);
    await tester.runAsync(() async {
      final box = await inkBox(await _rasterise(b, 400));
      expect(box[0], greaterThanOrEqualTo(0));
      expect(box[2], lessThan(b.width));
      expect(box[3], lessThan(b.height));
      expect(box[3], greaterThan(b.height * 0.8));
    });
  });

  testWidgets('placeholder for a 2D symbol is a square grid in bounds', (
    tester,
  ) async {
    final b = ZplBarcode(
      data: '{{sku}}',
      type: ZplBarcodeType.dataMatrix,
      height: 6,
    );
    expect(measureBarcodeSymbol(b), isNotNull); // encodable, still a token
    await tester.runAsync(() async {
      final box = await inkBox(await _rasterise(b, 400));
      expect(box[2], lessThan(b.width));
      expect(box[3], lessThan(b.width));
      expect(box[3], greaterThan(0));
    });
  });

  testWidgets('a real encoding error stays inside the bounds too', (
    tester,
  ) async {
    final b = ZplBarcode(
      data: 'not digits at all, a long message',
      type: ZplBarcodeType.ean13,
      height: 60,
      moduleWidth: 2,
    );
    expect(measureBarcodeSymbol(b), isNull);
    await tester.runAsync(() async {
      final box = await inkBox(await _rasterise(b, 400));
      expect(box[2], lessThan(b.width));
      expect(box[3], lessThan(b.height));
    });
  });

  testWidgets('a token behind a start invocation paints the placeholder', (
    tester,
  ) async {
    final b = ZplBarcode(
      data: '>9{{fnsku}}',
      type: ZplBarcodeType.code128,
      height: 50,
      code128Mode: ZplCode128Mode.none,
    );
    await tester.runAsync(() async {
      // Must not throw and must paint something (the placeholder pattern).
      final image = await _rasterise(b, 300);
      final rgba = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var inked = 0;
      for (var i = 3; i < rgba.lengthInBytes; i += 4) {
        if (rgba.getUint8(i) != 0) inked++;
      }
      expect(inked, greaterThan(0));
    });
    expect(isBarcodeDataPlaceholder(b), isTrue);
  });

  testWidgets('mode N reads digit pairs after >9, so the symbol is short', (
    tester,
  ) async {
    final b = ZplBarcode(
      data: '>9X001ABCDE1',
      type: ZplBarcodeType.code128,
      height: 50,
      moduleWidth: 2,
      code128Mode: ZplCode128Mode.none,
    );
    // Start A, one data symbol (00), check digit, stop: 46 modules.
    expect(measureBarcodeSymbol(b)!.width, 92);
    await tester.runAsync(() async {
      expect((await inkBox(await _rasterise(b, 300)))[2], greaterThan(0));
    });
  });

  testWidgets('mode N with no decodable text paints bars and no line', (
    tester,
  ) async {
    final b = ZplBarcode(
      data: '>9AB',
      type: ZplBarcodeType.code128,
      height: 50,
      moduleWidth: 2,
      code128Mode: ZplCode128Mode.none,
    );
    expect(measureBarcodeSymbol(b), isNotNull);
    expect(debugBarcodeTextPlacements(b), isEmpty);
    await tester.runAsync(() async {
      expect((await inkBox(await _rasterise(b, 300)))[2], greaterThan(0));
    });
  });
}
