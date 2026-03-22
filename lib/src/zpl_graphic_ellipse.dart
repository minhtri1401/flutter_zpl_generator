import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// A command to draw a graphic ellipse using the ZPL ^GE command.
class ZplGraphicEllipse extends ZplCommand {
  /// The x-axis position of the ellipse.
  final int x;

  /// The y-axis position of the ellipse.
  final int y;

  /// The width of the ellipse in dots.
  final int width;

  /// The height of the ellipse in dots.
  final int height;

  /// The border thickness in dots.
  final int borderThickness;

  /// The line color: 'B' for black, 'W' for white.
  final String lineColor;

  const ZplGraphicEllipse({
    this.x = 0,
    this.y = 0,
    required this.width,
    required this.height,
    this.borderThickness = 1,
    this.lineColor = 'B',
  });

  @override
  String toZpl(ZplConfiguration context) {
    return '^FO$x,$y\n^GE$width,$height,$borderThickness,$lineColor^FS\n';
  }

  @override
  int calculateWidth(ZplConfiguration config) => width;
}
