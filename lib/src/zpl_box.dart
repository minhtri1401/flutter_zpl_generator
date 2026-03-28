import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

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

  /// The line color of the box ('B' for black, 'W' for white).
  final String lineColor;

  /// The degree of corner rounding (0 for sharp, 8 for max rounding).
  final int cornerRounding;

  /// Whether to invert the print colors (white on black).
  final bool reversePrint;

  ZplBox({
    this.x = 0,
    this.y = 0,
    required this.width,
    required this.height,
    this.borderThickness = 1,
    this.lineColor = 'B',
    this.cornerRounding = 0,
    this.reversePrint = false,
  }) : assert(
         borderThickness >= 1 && borderThickness <= 32000,
         'Border thickness must be between 1 and 32,000 dots',
       ),
       assert(
         lineColor == 'B' || lineColor == 'W',
         'Line color must be B (black) or W (white)',
       ),
       assert(
         cornerRounding >= 0 && cornerRounding <= 8,
         'Corner rounding must be between 0 (no rounding) and 8 (maximum rounding)',
       );

  @override
  String toZpl(ZplConfiguration context) {
    final sb = StringBuffer();
    sb.writeln('^FO$x,$y');
    if (reversePrint) {
      sb.writeln('^FR');
    }
    sb.writeln(
      '^GB$width,$height,$borderThickness,$lineColor,$cornerRounding^FS',
    );
    return sb.toString();
  }

  @override
  int calculateWidth(ZplConfiguration config) {
    return width;
  }
}
