import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'zpl_canvas_painter.dart';

/// The result of [ZplRasterizer.render]: a PNG of the label at one pixel per
/// dot, plus how much of it is ink.
class ZplRaster {
  /// The label as PNG bytes, [width] x [height] pixels.
  final Uint8List png;

  /// Width in dots (one pixel per dot).
  final int width;

  /// Height in dots (one pixel per dot).
  final int height;

  /// Share of pixels that are ink (luminance below 128), from 0 to 1.
  final double inkRatio;

  const ZplRaster({
    required this.png,
    required this.width,
    required this.height,
    required this.inkRatio,
  });
}

/// Renders a [ZplGenerator] to a PNG offscreen, with the same painter that
/// backs [ZplNativePreview], so no network and no widget tree are needed.
///
/// Needs the Flutter engine bindings: call it from a running app, or from a
/// test after `TestWidgetsFlutterBinding.ensureInitialized()`. It uses
/// `dart:ui`, so it does not run in a plain Dart isolate.
///
/// The output has one pixel per dot on a white background. Output is
/// deterministic on one machine and font set; text anti-aliasing can differ
/// between platforms, so compare pixels rather than bytes across devices.
/// It shows what [ZplNativePreview] shows, not the printer's output, so the
/// preview's gaps apply (custom fonts, serials, `^LH`, most of `ZplRaw`).
class ZplRasterizer {
  const ZplRasterizer();

  /// Paints [generator] white-first at [widthDots] x [heightDots]. These
  /// default to the configuration's `printWidth` and `labelLength`, else
  /// 406 x 609.
  Future<ZplRaster> render(
    ZplGenerator generator, {
    int? widthDots,
    int? heightDots,
  }) async {
    final width = widthDots ?? generator.config.printWidth ?? 406;
    final height = heightDots ?? generator.config.labelLength ?? 609;
    final size = ui.Size(width.toDouble(), height.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Offset.zero & size);
    canvas.drawRect(
      ui.Offset.zero & size,
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    ZplCanvasPainter(generator: generator).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    try {
      final pngData = await image.toByteData(format: ui.ImageByteFormat.png);
      final rawData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      return ZplRaster(
        png: pngData!.buffer.asUint8List(
          pngData.offsetInBytes,
          pngData.lengthInBytes,
        ),
        width: width,
        height: height,
        inkRatio: _inkRatio(rawData!, width * height),
      );
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  static double _inkRatio(ByteData rgba, int pixels) {
    if (pixels == 0) return 0;
    var ink = 0;
    for (var i = 0; i < pixels; i++) {
      final o = i * 4;
      final luminance =
          0.299 * rgba.getUint8(o) +
          0.587 * rgba.getUint8(o + 1) +
          0.114 * rgba.getUint8(o + 2);
      if (luminance < 128) ink++;
    }
    return ink / pixels;
  }
}
