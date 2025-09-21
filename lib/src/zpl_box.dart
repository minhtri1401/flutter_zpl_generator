import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'zpl_command_base.dart';

/// A class to handle the Graphic Box command (^GB).
class ZplBox extends ZplCommand {
  /// The x-axis position of the box's top-left corner.
  final int x;

  /// The y-axis position of the box's top-left corner.
  final int y;

  /// The width of the box in dots.
  final int width;

  /// The height of the box in dots.
  final int height;

  /// The thickness of the border in dots.
  final int borderThickness;

  /// The degree of corner rounding (0 for sharp, 8 for max rounding).
  final int cornerRounding;

  const ZplBox({
    this.x = 0,
    this.y = 0,
    required this.width,
    required this.height,
    this.borderThickness = 1,
    this.cornerRounding = 0,
  });

  @override
  String toZpl() {
    final sb = StringBuffer();
    sb.writeln('^FO$x,$y');
    sb.writeln('^GB$width,$height,$borderThickness,B,$cornerRounding^FS');
    return sb.toString();
  }

  @override
  int calculateWidth(ZplConfiguration? config) {
    return width;
  }
}
