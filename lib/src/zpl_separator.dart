import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'zpl_box.dart';
import 'zpl_text.dart';
import 'enums.dart';

/// A widget that creates separator lines using either box drawing or repeated characters.
///
/// Supports both horizontal and vertical orientations, custom characters,
/// padding control, and automatic width/height calculation based on configuration.
class ZplSeparator extends ZplCommand {
  /// The x-axis position of the separator.
  final int x;

  /// The y-axis position of the separator.
  final int y;

  /// The type of separator to create.
  final ZplSeparatorType type;

  /// The character to repeat (only used when type is character).
  final String character;

  /// The thickness of the line in dots (only used when type is box).
  final int thickness;

  /// The orientation of the separator.
  final ZplOrientation orientation;

  /// Padding from the left edge (reduces length for horizontal separators).
  final int paddingLeft;

  /// Padding from the right edge (reduces length for horizontal separators).
  final int paddingRight;

  /// Padding from the top edge (reduces length for vertical separators).
  final int paddingTop;

  /// Padding from the bottom edge (reduces length for vertical separators).
  final int paddingBottom;

  /// Optional fixed length. If null, uses full available width/height minus padding.
  final int? length;

  /// Font height for character-based separators.
  final int fontHeight;

  /// Font width for character-based separators.
  final int fontWidth;

  /// Optional configuration context for automatic sizing
  ZplConfiguration? _configuration;

  ZplSeparator({
    this.x = 0,
    this.y = 0,
    this.type = ZplSeparatorType.box,
    this.character = '-',
    this.thickness = 1,
    this.orientation = ZplOrientation.normal,
    this.paddingLeft = 0,
    this.paddingRight = 0,
    this.paddingTop = 0,
    this.paddingBottom = 0,
    this.length,
    this.fontHeight = 12,
    this.fontWidth = 10,
  });

  /// Set configuration context for automatic sizing
  void setConfiguration(ZplConfiguration config) {
    _configuration = config;
  }

  @override
  String toZpl() {
    final isHorizontal =
        orientation == ZplOrientation.normal ||
        orientation == ZplOrientation.inverted180;

    if (type == ZplSeparatorType.box) {
      return _generateBoxSeparator(isHorizontal);
    } else {
      return _generateCharacterSeparator(isHorizontal);
    }
  }

  /// Generate a separator using ZPL box drawing
  String _generateBoxSeparator(bool isHorizontal) {
    final calculatedLength = _calculateLength(isHorizontal);

    if (isHorizontal) {
      // Horizontal line
      final startX = x + paddingLeft;
      return ZplBox(
        x: startX,
        y: y,
        width: calculatedLength,
        height: thickness,
      ).toZpl();
    } else {
      // Vertical line
      final startY = y + paddingTop;
      return ZplBox(
        x: x,
        y: startY,
        width: thickness,
        height: calculatedLength,
      ).toZpl();
    }
  }

  /// Generate a separator using repeated characters
  String _generateCharacterSeparator(bool isHorizontal) {
    if (isHorizontal) {
      // For horizontal character separators, we need to calculate how many characters
      // fit in the available space (total width minus padding)
      final availableWidth = _getAvailableWidth();

      // Use a more accurate character width calculation
      // For ZPL fonts, the actual character width is closer to fontWidth dots
      final actualCharWidth = fontWidth.toDouble();
      final charCount = (availableWidth / actualCharWidth).floor();
      final separatorText = character * charCount;

      return ZplText(
        x: x + paddingLeft,
        y: y,
        text: separatorText,
        fontHeight: fontHeight,
        fontWidth: fontWidth,
        orientation: orientation,
      ).toZpl();
    } else {
      // For vertical character separators, we create multiple single characters
      final sb = StringBuffer();
      final availableHeight = _getAvailableHeight();
      final charHeight = fontHeight;
      final charCount = (availableHeight / charHeight).floor();

      for (int i = 0; i < charCount; i++) {
        final charY = y + paddingTop + (i * charHeight);
        sb.write(
          ZplText(
            x: x,
            y: charY,
            text: character,
            fontHeight: fontHeight,
            fontWidth: fontWidth,
            orientation: orientation,
          ).toZpl(),
        );
      }

      return sb.toString();
    }
  }

  /// Get available width for horizontal separators (accounting for padding)
  int _getAvailableWidth() {
    if (length != null) {
      return (length! - paddingLeft - paddingRight).clamp(1, length!);
    }

    // Calculate based on available space from configuration
    if (_configuration != null) {
      final labelWidth = _configuration!.printWidth ?? 406;
      return (labelWidth - paddingLeft - paddingRight).clamp(1, labelWidth);
    }

    // Default fallback
    return (406 - paddingLeft - paddingRight).clamp(1, 406);
  }

  /// Get available height for vertical separators (accounting for padding)
  int _getAvailableHeight() {
    if (length != null) {
      return (length! - paddingTop - paddingBottom).clamp(1, length!);
    }

    // Calculate based on available space from configuration
    if (_configuration != null) {
      final labelHeight = _configuration!.labelLength ?? 200;
      return (labelHeight - paddingTop - paddingBottom).clamp(1, labelHeight);
    }

    // Default fallback
    return (200 - paddingTop - paddingBottom).clamp(1, 200);
  }

  /// Calculate the length of the separator based on orientation and padding
  int _calculateLength(bool isHorizontal) {
    if (length != null) {
      // Use fixed length minus appropriate padding
      if (isHorizontal) {
        return (length! - paddingLeft - paddingRight).clamp(1, length!);
      } else {
        return (length! - paddingTop - paddingBottom).clamp(1, length!);
      }
    }

    // Calculate based on available space from configuration
    if (_configuration != null) {
      if (isHorizontal) {
        final labelWidth = _configuration!.printWidth ?? 406;
        return (labelWidth - paddingLeft - paddingRight).clamp(1, labelWidth);
      } else {
        final labelHeight = _configuration!.labelLength ?? 200;
        return (labelHeight - paddingTop - paddingBottom).clamp(1, labelHeight);
      }
    }

    // Default fallback
    if (isHorizontal) {
      return (406 - paddingLeft - paddingRight).clamp(1, 406);
    } else {
      return (200 - paddingTop - paddingBottom).clamp(1, 200);
    }
  }

  @override
  int calculateWidth(ZplConfiguration? config) {
    final isHorizontal =
        orientation == ZplOrientation.normal ||
        orientation == ZplOrientation.inverted180;

    if (isHorizontal) {
      // For horizontal separators, return the total width including padding
      return _getAvailableWidth() + paddingLeft + paddingRight;
    } else {
      return thickness; // Vertical separators are thin
    }
  }

  /// Calculate the height of the separator
  int calculateHeight(ZplConfiguration? config) {
    final isHorizontal =
        orientation == ZplOrientation.normal ||
        orientation == ZplOrientation.inverted180;

    if (isHorizontal) {
      return thickness; // Horizontal separators are thin
    } else {
      return _getAvailableHeight() + paddingTop + paddingBottom;
    }
  }
}
