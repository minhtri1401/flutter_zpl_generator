import 'zpl_command_base.dart';
import 'enums.dart';

/// A class to handle text-related commands (^FO, ^A, ^FD, ^FS).
class ZplText extends ZplCommand {
  /// The x-axis position of the text field.
  final int x;

  /// The y-axis position of the text field.
  final int y;

  /// The text content to be printed.
  final String text;

  /// The font to be used.
  final ZplFont? font;

  /// A single character alias (A-Z, 0-9) for a downloaded font.
  /// If provided, this will be used instead of [font].
  final String? fontAlias;

  /// The height of the font in dots.
  final int? fontHeight;

  /// The width of the font in dots.
  final int? fontWidth;

  /// The orientation of the text field.
  final ZplOrientation orientation;

  const ZplText({
    required this.x,
    required this.y,
    required this.text,
    this.font = ZplFont.zero,
    this.fontAlias,
    this.fontHeight,
    this.fontWidth,
    this.orientation = ZplOrientation.normal,
  });

  @override
  String toZpl() {
    final sb = StringBuffer();
    sb.writeln('^FO$x,$y');

    final String fontName;
    if (fontAlias != null) {
      fontName = fontAlias!;
    } else {
      fontName = font == ZplFont.zero ? '0' : font!.name.toUpperCase();
    }

    final orientationCode = _getOrientationCode();
    sb.writeln(
      '^A$fontName$orientationCode,${fontHeight ?? ''},${fontWidth ?? ''}',
    );
    sb.writeln('^FD$text^FS');
    return sb.toString();
  }

  String _getOrientationCode() {
    switch (orientation) {
      case ZplOrientation.normal:
        return 'N';
      case ZplOrientation.rotated90:
        return 'R';
      case ZplOrientation.inverted180:
        return 'I';
      case ZplOrientation.readFromBottomUp270:
        return 'B';
    }
  }
}
