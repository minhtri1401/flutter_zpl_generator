import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'zpl_canvas_painter.dart';

/// A widget that renders ZPL commands locally using Flutter's CustomPainter.
/// This allows 100% offline previewing without relying on the Labelary API.
class ZplNativePreview extends StatelessWidget {
  /// The [ZplGenerator] containing the label commands to be rendered.
  final ZplGenerator generator;

  /// Background color for the canvas, defaulting to white.
  final Color backgroundColor;

  const ZplNativePreview({
    super.key,
    required this.generator,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final config = generator.config;
    final width = config.printWidth?.toDouble() ?? 406.0;
    final height = config.labelLength?.toDouble() ?? 609.0;

    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      child: CustomPaint(
        size: Size(width, height),
        painter: ZplCanvasPainter(generator: generator),
      ),
    );
  }
}
