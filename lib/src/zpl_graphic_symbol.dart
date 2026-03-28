import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// Supported types of graphic symbols for the ^GS command.
enum ZplGraphicSymbolType {
  /// Registered Trademark Symbol (®)
  registeredTrademark('A'),

  /// Copyright Symbol (©)
  copyright('B'),

  /// Underwriters Laboratories (UL) Symbol
  ul('C'),

  /// Canadian Standards Association (CSA) Symbol
  csa('D'),

  /// VDE Symbol
  vde('E');

  final String value;
  const ZplGraphicSymbolType(this.value);
}

/// A class to handle the Graphic Symbol command (^GS).
///
/// This command enables you to generate registered trademark, copyright, UL, and other symbols.
class ZplGraphicSymbol extends ZplCommand {
  /// The x-axis position of the symbol.
  final int x;

  /// The y-axis position of the symbol.
  final int y;

  /// The type of symbol to draw.
  final ZplGraphicSymbolType symbol;

  /// The width of the symbol in dots.
  final int width;

  /// The height of the symbol in dots.
  final int height;

  /// The orientation of the symbol (N = Normal, R = Rotated, I = Inverted, B = Bottom-up).
  final String orientation;

  ZplGraphicSymbol({
    this.x = 0,
    this.y = 0,
    required this.symbol,
    required this.width,
    required this.height,
    this.orientation = 'N',
  }) : assert(
          orientation == 'N' ||
              orientation == 'R' ||
              orientation == 'I' ||
              orientation == 'B',
          'Orientation must be N, R, I, or B',
        );

  @override
  String toZpl(ZplConfiguration context) {
    return '^FO$x,$y\n^GS$orientation,$height,$width\n^FD${symbol.value}^FS\n';
  }

  @override
  int calculateWidth(ZplConfiguration config) {
    return width;
  }
}
