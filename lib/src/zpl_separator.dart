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

  /// Maximum width constraint (set by layout containers like ZplGridRow).
  final int? maxWidth;

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
    this.maxWidth,
  });

  @override
  String toZpl(ZplConfiguration context) {
    final isHorizontal = orientation == ZplOrientation.normal ||
        orientation == ZplOrientation.inverted180;

    if (type == ZplSeparatorType.box) {
      return _generateBoxSeparator(isHorizontal, context);
    } else {
      return _generateCharacterSeparator(isHorizontal, context);
    }
  }

  /// Generate a separator using ZPL box drawing.
  String _generateBoxSeparator(bool isHorizontal, ZplConfiguration context) {
    final calculatedLength = _calculateLength(isHorizontal, context);

    if (isHorizontal) {
      final startX = x + paddingLeft;
      return ZplBox(
        x: startX,
        y: y,
        width: calculatedLength,
        height: thickness,
      ).toZpl(context);
    } else {
      final startY = y + paddingTop;
      return ZplBox(
        x: x,
        y: startY,
        width: thickness,
        height: calculatedLength,
      ).toZpl(context);
    }
  }

  /// Generate a separator using repeated characters.
  String _generateCharacterSeparator(
    bool isHorizontal,
    ZplConfiguration context,
  ) {
    if (isHorizontal) {
      final availableWidth = _getAvailableWidth(context);
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
      ).toZpl(context);
    } else {
      final sb = StringBuffer();
      final availableHeight = _getAvailableHeight(context);
      final charCount = (availableHeight / fontHeight).floor();

      for (int i = 0; i < charCount; i++) {
        final charY = y + paddingTop + (i * fontHeight);
        sb.write(
          ZplText(
            x: x,
            y: charY,
            text: character,
            fontHeight: fontHeight,
            fontWidth: fontWidth,
            orientation: orientation,
          ).toZpl(context),
        );
      }

      return sb.toString();
    }
  }

  /// Get available width for horizontal separators (accounting for padding).
  int _getAvailableWidth(ZplConfiguration context) {
    if (length != null) {
      return (length! - paddingLeft - paddingRight).clamp(1, length!);
    }
    final labelWidth = maxWidth ?? context.printWidth ?? 406;
    return (labelWidth - paddingLeft - paddingRight).clamp(1, labelWidth);
  }

  /// Get available height for vertical separators (accounting for padding).
  int _getAvailableHeight(ZplConfiguration context) {
    if (length != null) {
      return (length! - paddingTop - paddingBottom).clamp(1, length!);
    }
    final labelHeight = context.labelLength ?? 200;
    return (labelHeight - paddingTop - paddingBottom).clamp(1, labelHeight);
  }

  /// Calculate the length of the separator based on orientation and padding.
  int _calculateLength(bool isHorizontal, ZplConfiguration context) {
    if (length != null) {
      if (isHorizontal) {
        return (length! - paddingLeft - paddingRight).clamp(1, length!);
      } else {
        return (length! - paddingTop - paddingBottom).clamp(1, length!);
      }
    }

    if (isHorizontal) {
      final labelWidth = maxWidth ?? context.printWidth ?? 406;
      return (labelWidth - paddingLeft - paddingRight).clamp(1, labelWidth);
    } else {
      final labelHeight = context.labelLength ?? 200;
      return (labelHeight - paddingTop - paddingBottom).clamp(1, labelHeight);
    }
  }

  @override
  int calculateWidth(ZplConfiguration config) {
    final isHorizontal = orientation == ZplOrientation.normal ||
        orientation == ZplOrientation.inverted180;

    if (isHorizontal) {
      return _getAvailableWidth(config) + paddingLeft + paddingRight;
    } else {
      return thickness;
    }
  }

  /// Calculate the height of the separator.
  int calculateHeight(ZplConfiguration config) {
    final isHorizontal = orientation == ZplOrientation.normal ||
        orientation == ZplOrientation.inverted180;

    if (isHorizontal) {
      return thickness;
    } else {
      return _getAvailableHeight(config) + paddingTop + paddingBottom;
    }
  }
}
