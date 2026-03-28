import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'zpl_font_asset.dart';
import 'enums.dart';
import 'zpl_serial_config.dart';

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

  /// The horizontal alignment of the text.
  final ZplAlignment? alignment;

  /// Horizontal padding around the text. Affects the x coordinate positioning.
  final int paddingLeft;
  final int paddingRight;

  /// The maximum number of lines for the text. If the text exceeds this,
  /// it will be truncated. Default is 1 (single line).
  final int maxLines;

  /// The amount of vertical spacing between lines of text, in dots.
  /// Only applies when maxLines > 1. Default is 0.
  final int lineSpacing;

  /// Optional custom TrueType font to use for this text.
  final ZplFontAsset? customFont;

  /// Maximum width constraint (set by layout containers like ZplGridRow).
  /// When set, alignment uses this width instead of the full label width.
  final int? maxWidth;

  /// Whether to invert the print colors (white on black).
  final bool reversePrint;

  /// Optional serialization config. If provided, replaces ^FD with ^SN.
  final ZplSerialConfig? serialization;

  ZplText({
    this.x = 0,
    this.y = 0,
    required this.text,
    this.font = ZplFont.zero,
    this.fontAlias,
    this.fontHeight,
    this.fontWidth,
    this.orientation = ZplOrientation.normal,
    this.alignment,
    this.paddingLeft = 0,
    this.paddingRight = 0,
    this.maxLines = 1,
    this.lineSpacing = 0,
    this.customFont,
    this.maxWidth,
    this.reversePrint = false,
    this.serialization,
  });

  @override
  String toZpl(ZplConfiguration context) {
    final sb = StringBuffer();
    final effectiveWidth = maxWidth ?? context.printWidth ?? 406;

    if (alignment != null && alignment != ZplAlignment.left) {
      final availableWidth = effectiveWidth - paddingLeft - paddingRight;

      if (maxWidth != null) {
        // Inside a layout container — x is set by container, use maxWidth for ^FB
        sb.writeln('^FO$x,$y');
        _writeFontCommand(sb);
        final justification = _getJustificationCode();
        sb.writeln(
          '^FB$availableWidth,$maxLines,$lineSpacing,$justification,0',
        );
        if (reversePrint) sb.writeln('^FR');
        _writeDataCommand(sb);
      } else if (x == 0) {
        // Standalone text with alignment — use full label width
        sb.writeln('^FO0,$y');
        _writeFontCommand(sb);
        final justification = _getJustificationCode();
        sb.writeln(
          '^FB$availableWidth,$maxLines,$lineSpacing,$justification,0',
        );
        if (reversePrint) sb.writeln('^FR');
        _writeDataCommand(sb);
      } else {
        // Manual position with alignment hint — fall through to positioned output
        sb.writeln('^FO$x,$y');
        _writeFontCommand(sb);
        if (maxLines > 1) {
          final wrapWidth = effectiveWidth - x - paddingRight;
          sb.writeln('^FB$wrapWidth,$maxLines,$lineSpacing,L,0');
        }
        if (reversePrint) sb.writeln('^FR');
        _writeDataCommand(sb);
      }
    } else {
      // Left alignment or no alignment
      final alignedX = (x == 0 && maxWidth == null) ? getAlignedX(context) : x;
      sb.writeln('^FO$alignedX,$y');
      _writeFontCommand(sb);
      if (maxLines > 1) {
        final wrapWidth = effectiveWidth - alignedX - paddingRight;
        sb.writeln('^FB$wrapWidth,$maxLines,$lineSpacing,L,0');
      }
      if (reversePrint) sb.writeln('^FR');
      _writeDataCommand(sb);
    }

    return sb.toString();
  }

  /// Writes the font selection command (^A) to the buffer.
  void _writeFontCommand(StringBuffer sb) {
    final orientationCode = _getOrientationCode();
    if (customFont != null) {
      sb.writeln(
        '^A@$orientationCode,${fontHeight ?? 20},${fontWidth ?? 20},${customFont!.printerPath}',
      );
    } else if (fontAlias != null) {
      sb.writeln(
        '^A$fontAlias$orientationCode,${fontHeight ?? ''},${fontWidth ?? ''}',
      );
    } else {
      final fontName = font == ZplFont.zero ? '0' : font!.name.toUpperCase();
      sb.writeln(
        '^A$fontName$orientationCode,${fontHeight ?? ''},${fontWidth ?? ''}',
      );
    }
  }

  /// Writes data payload via ^FD or auto-incrementing ^SN
  void _writeDataCommand(StringBuffer sb) {
    if (serialization != null) {
      final leading = serialization!.leadingZeros ? 'Y' : 'N';
      sb.writeln('^SN$text,${serialization!.increment},$leading^FS');
    } else {
      sb.writeln('^FD$text^FS');
    }
  }

  /// Calculate the X position based on alignment, available width, and left padding.
  int getAlignedX(ZplConfiguration context) {
    int baseX = x + paddingLeft;

    if (x != 0 || alignment == null) {
      return baseX;
    }

    final labelWidth = maxWidth ?? context.printWidth ?? 406;
    final textWidth = calculateWidth(context);
    switch (alignment!) {
      case ZplAlignment.center:
        return baseX +
            ((labelWidth - textWidth) ~/ 2).clamp(0, labelWidth - 1).toInt();
      case ZplAlignment.right:
        return baseX +
            (labelWidth - textWidth).clamp(0, labelWidth - 1).toInt();
      case ZplAlignment.left:
        return baseX;
    }
  }

  /// Calculate the approximate width of the text.
  int _calculateTextWidth() {
    final baseHeight = fontHeight ?? 12;
    final widthScale = (fontWidth ?? 10) / 10.0;
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

  /// Get the justification code for ^FB command.
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
  int calculateWidth(ZplConfiguration config) {
    return _calculateTextWidth() + paddingLeft + paddingRight;
  }

  /// Calculate the height of the text including multiple lines and line spacing.
  int calculateHeight() {
    final baseHeight = fontHeight ?? 12;
    return (baseHeight * maxLines) + (lineSpacing * (maxLines - 1));
  }
}
