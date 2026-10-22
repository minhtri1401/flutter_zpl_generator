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
}
