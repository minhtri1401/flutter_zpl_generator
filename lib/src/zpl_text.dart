import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
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

  /// The horizontal alignment of the text (requires configuration context)
  final ZplAlignment? alignment;

  /// Optional configuration context for alignment features
  ZplConfiguration? _configuration;

  ZplText({
    this.x = 0,
    this.y = 0,
    required this.text,
    this.font = ZplFont.zero,
    this.fontAlias,
    this.fontHeight,
    this.fontWidth,
    this.orientation = ZplOrientation.normal,
    this.alignment = ZplAlignment.left,
  });

  /// Set configuration context for alignment features
  void setConfiguration(ZplConfiguration config) {
    _configuration = config;
  }

  @override
  String toZpl() {
    final sb = StringBuffer();

    // Use ^FB (Field Block) for alignment when configuration is available and alignment is specified
    if (_configuration != null &&
        alignment != null &&
        alignment != ZplAlignment.left &&
        x == 0) {
      // Use Field Block for precise ZPL alignment
      final labelWidth = _configuration!.printWidth ?? 406;
      sb.writeln('^FO0,$y');

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

      // ^FB command: width, max_lines, line_spacing, justification, hanging_indent
      final justification = _getJustificationCode();
      sb.writeln('^FB$labelWidth,1,0,$justification,0');
      sb.writeln('^FD$text^FS');
    } else {
      // Fall back to manual positioning for specific coordinates or left alignment
      final alignedX = x == 0 ? _calculateAlignedX() : x;
      sb.writeln('^FO$alignedX,$y');

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
    }
    return sb.toString();
  }

  /// Calculate the X position based on alignment and available width
  int _calculateAlignedX() {
    // If x position is already set (non-zero), it means we're inside a layout container
    // In that case, use the positioned x rather than applying alignment
    if (x != 0 || alignment == null || _configuration == null) {
      return x; // Use specified x position (set by layout container or user)
    }

    final labelWidth =
        _configuration!.printWidth ?? 406; // Default to 2" at 203dpi
    final textWidth = _calculateTextWidth();

    int calculatedX;
    switch (alignment!) {
      case ZplAlignment.center:
        calculatedX = ((labelWidth - textWidth) ~/ 2);
        break;
      case ZplAlignment.right:
        calculatedX = (labelWidth - textWidth);
        break;
      case ZplAlignment.left:
        calculatedX = 0;
        break;
    }

    // Ensure X position is never negative and doesn't exceed label width
    return calculatedX.clamp(0, labelWidth - 1);
  }

  /// Calculate the approximate width of the text
  int _calculateTextWidth() {
    // ZPL Font calculation is complex due to proportional fonts
    // Font 0 (default) is proportional - characters have different widths
    // This is an approximation for layout purposes
    final baseHeight = fontHeight ?? 12;
    final widthScale = (fontWidth ?? 10) / 10.0;

    // For proportional fonts, use a more conservative estimate
    // Average character width is roughly 40-50% of font height for readable text
    // This is more realistic than the previous 60% calculation
    final avgCharWidth = (baseHeight * 0.4 * widthScale).round();
    return text.length * avgCharWidth;
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

  /// Get the justification code for ^FB command
  String _getJustificationCode() {
    switch (alignment!) {
      case ZplAlignment.left:
        return 'L';
      case ZplAlignment.center:
        return 'C';
      case ZplAlignment.right:
        return 'R';
    }
  }

  @override
  int calculateWidth(ZplConfiguration? config) {
    return _calculateTextWidth();
  }
}
