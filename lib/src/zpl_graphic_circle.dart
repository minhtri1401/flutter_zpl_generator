import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// A command to draw a graphic circle using the ZPL ^GC command.
class ZplGraphicCircle extends ZplCommand {
  /// The x-axis position of the circle center.
  final int x;

  /// The y-axis position of the circle center.
  final int y;

  /// The diameter of the circle in dots.
  final int diameter;

  /// The border thickness in dots.
  final int borderThickness;

  /// The line color: 'B' for black, 'W' for white.
  final String lineColor;

  const ZplGraphicCircle({
    this.x = 0,
    this.y = 0,
    required this.diameter,
    this.borderThickness = 1,
    this.lineColor = 'B',
  });

  @override
  String toZpl(ZplConfiguration context) {
    return '^FO$x,$y\n^GC$diameter,$borderThickness,$lineColor^FS\n';
  }

  @override
  int calculateWidth(ZplConfiguration config) => diameter;
}
