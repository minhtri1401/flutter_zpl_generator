import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'zpl_canvas_painter.dart';

/// The result of [ZplRasterizer.render]: a PNG of the label at [scale] pixels
/// per dot, plus how much of it is ink.
class ZplRaster {
  /// The label as PNG bytes, [width] x [height] pixels.
  final Uint8List png;

  /// Width in pixels: the label's dot width times [scale].
  final int width;

  /// Height in pixels: the label's dot height times [scale].
  final int height;

  /// Share of pixels that are ink (luminance below 128), from 0 to 1.
  final double inkRatio;

  /// Pixels per dot. 1 means one pixel per dot.
  final double scale;

  const ZplRaster({
    required this.png,
    required this.width,
    required this.height,
    required this.inkRatio,
    this.scale = 1.0,
  });
}

/// Renders a [ZplGenerator] to a PNG offscreen, with the same painter that
/// backs [ZplNativePreview], so no network and no widget tree are needed.
///
/// Needs the Flutter engine bindings: call it from a running app, or from a
/// test after `TestWidgetsFlutterBinding.ensureInitialized()`. It uses
/// `dart:ui`, so it does not run in a plain Dart isolate.
///
/// The output has `scale` pixels per dot on a white background (one pixel per
/// dot by default). Output is
/// deterministic on one machine and font set; text anti-aliasing can differ
/// between platforms, so compare pixels rather than bytes across devices.
/// It shows what [ZplNativePreview] shows, not the printer's output, so the
/// preview's gaps apply (custom fonts, serials, `^LH`, most of `ZplRaw`).
class ZplRasterizer {
  const ZplRasterizer();

  /// Paints [generator] white-first at [widthDots] x [heightDots], drawn at
  /// [scale] pixels per dot. These default to the configuration's
  /// `printWidth` and `labelLength`, else 406 x 609. Throws an
  /// [ArgumentError] when [scale] is not finite or not greater than 0.
  Future<ZplRaster> render(
    ZplGenerator generator, {
    int? widthDots,
    int? heightDots,
    double scale = 1.0,
  }) async {
    if (!scale.isFinite || scale <= 0) {
      throw ArgumentError.value(
        scale,
        'scale',
        'must be finite and greater than 0',
      );
    }
    final widthDotsValue = widthDots ?? generator.config.printWidth ?? 406;
    final heightDotsValue = heightDots ?? generator.config.labelLength ?? 609;
    final size = ui.Size(widthDotsValue.toDouble(), heightDotsValue.toDouble());
    final width = _pixels(widthDotsValue, scale);
    final height = _pixels(heightDotsValue, scale);
    final pixelSize = ui.Size(width.toDouble(), height.toDouble());

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Offset.zero & pixelSize);
    canvas.drawRect(
      ui.Offset.zero & pixelSize,
      ui.Paint()..color = const ui.Color(0xFFFFFFFF),
    );
    canvas.scale(scale);
    ZplCanvasPainter(generator: generator).paint(canvas, size);
    final picture = recorder.endRecording();
    // Both are native handles: dispose them whatever fails, including
    // `toImage` itself (an empty size throws "Invalid image dimensions").
    ui.Image? image;
    try {
      image = await picture.toImage(width, height);
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
        scale: scale,
      );
    } finally {
      image?.dispose();
      picture.dispose();
    }
  }

  /// Pixel size of [dots] at [scale], at least one pixel. Non-positive sizes
  /// pass through unchanged so `toImage` still rejects them.
  static int _pixels(int dots, double scale) =>
      dots <= 0 ? dots : max(1, (dots * scale).round());

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
