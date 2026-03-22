import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// A command to draw a graphic diagonal line using the ZPL ^GD command.
class ZplGraphicDiagonalLine extends ZplCommand {
  /// The x-axis position of the diagonal line.
  final int x;

  /// The y-axis position of the diagonal line.
  final int y;

  /// The width of the bounding box in dots.
  final int width;

  /// The height of the bounding box in dots.
  final int height;

  /// The border thickness in dots.
  final int borderThickness;

  /// The line color: 'B' for black, 'W' for white.
  final String lineColor;

  /// The orientation of the diagonal line: 'R' for right-leaning, 'L' for left-leaning.
  final String orientation;

  const ZplGraphicDiagonalLine({
    this.x = 0,
    this.y = 0,
    required this.width,
    required this.height,
    this.borderThickness = 1,
    this.lineColor = 'B',
    this.orientation = 'R',
  });

  @override
  String toZpl(ZplConfiguration context) {
    return '^FO$x,$y\n^GD$width,$height,$borderThickness,$lineColor,$orientation^FS\n';
  }

  @override
  int calculateWidth(ZplConfiguration config) => width;
}
