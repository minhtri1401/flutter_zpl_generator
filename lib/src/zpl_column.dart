import 'zpl_command_base.dart';
import 'zpl_text.dart';
import 'zpl_barcode.dart';
import 'zpl_image.dart';
import 'zpl_box.dart';
import 'zpl_row.dart';
import 'zpl_separator.dart';
import 'zpl_configuration.dart';
import 'enums.dart';

/// A layout helper to arrange multiple [ZplCommand] objects vertically in a column.
/// This class does not generate ZPL itself but modifies its children to align them.
/// It can optionally use configuration context for advanced alignment features.
class ZplColumn extends ZplCommand {
  final int x;
  final int y;
  final List<ZplCommand> children;
  final int spacing;
  final ZplAlignment alignment;

  /// Optional configuration context for advanced alignment features
  ZplConfiguration? _configuration;

  ZplColumn({
    this.x = 0,
    this.y = 0,
    required this.children,
    this.spacing = 10,
    this.alignment = ZplAlignment.left,
  }) {
    // Validate that children don't contain nested ZplColumns
    for (final child in children) {
      if (child is ZplColumn) {
        throw ArgumentError(
          'ZplColumn cannot contain another ZplColumn. Nested columns are not supported.',
        );
      }
    }
  }

  /// Set configuration context for advanced alignment features
  void setConfiguration(ZplConfiguration config) {
    _configuration = config;
  }

  @override
  String toZpl() {
    final sb = StringBuffer();
    var currentY = y;

    for (var child in children) {
      // For column alignment, all children should inherit the column's alignment
      // Don't calculate individual alignments - use the column's x position
      final childX = x; // All children use the same x position

      // Create a new instance of the child with updated coordinates
      final updatedChild = _updateChildPosition(child, childX, currentY);
      sb.write(updatedChild.toZpl());

      // Calculate height based on element type
      final elementHeight = _calculateElementHeight(child);
      currentY += elementHeight + spacing;
    }

    return sb.toString();
  }

  /// Calculate the X position based on alignment and available width
  int _calculateAlignedX(ZplCommand child) {
    if (alignment == ZplAlignment.left || _configuration == null) {
      return x; // Default to left alignment
    }

    final labelWidth = _configuration!.printWidth ?? 406;
    final childWidth = _calculateElementWidth(child);

    int calculatedX;
    switch (alignment) {
      case ZplAlignment.center:
        calculatedX = x + ((labelWidth - childWidth) ~/ 2);
        break;
      case ZplAlignment.right:
        calculatedX = x + (labelWidth - childWidth);
        break;
      case ZplAlignment.left:
        calculatedX = x;
        break;
    }

    // Ensure X position is never negative and doesn't exceed label width
    return calculatedX.clamp(0, labelWidth - 1);
  }

  /// Calculate the width of an element for alignment purposes
  int _calculateElementWidth(ZplCommand element) {
    return element.calculateWidth(_configuration);
  }

  /// Calculate estimated height of an element
  /// Note: This is a rough estimation. For precise positioning,
  /// you would need to measure actual rendered dimensions.
  int _calculateElementHeight(ZplCommand element) {
    if (element is ZplText) {
      return element.calculateHeight();
    }
    if (element is ZplBarcode) {
      return element.height;
    }
    if (element is ZplBox) {
      return element.height;
    }
    if (element is ZplImage) {
      // Use the actual image height from the decoded image
      try {
        return element.height;
      } catch (e) {
        // Fallback if image decoding fails
        return 60;
      }
    }
    if (element is ZplRow) {
      // For a row, calculate the maximum height of its children
      int maxHeight = 0;
      for (final child in element.children) {
        final childHeight = _calculateElementHeight(child);
        if (childHeight > maxHeight) {
          maxHeight = childHeight;
        }
      }
      return maxHeight > 0 ? maxHeight : 20;
    }
    if (element is ZplSeparator) {
      return element.calculateHeight(_configuration);
    }
    return 20; // Default fallback
  }

  ZplCommand _updateChildPosition(ZplCommand child, int newX, int newY) {
    if (child is ZplText) {
      // Inherit column's alignment if child doesn't have its own alignment
      final childAlignment = child.alignment ?? alignment;

      final newText = ZplText(
        x: 0, // Always use x: 0 to allow ^FB alignment to work
        y: newY,
        text: child.text,
        font: child.font,
        fontAlias: child.fontAlias,
        fontHeight: child.fontHeight,
        fontWidth: child.fontWidth,
        orientation: child.orientation,
        alignment: childAlignment, // Use inherited or child's alignment
        paddingLeft: child.paddingLeft, // Preserve padding
        paddingRight: child.paddingRight, // Preserve padding
      );

      // Pass configuration to the new text instance
      if (_configuration != null) {
        newText.setConfiguration(_configuration!);
      }

      return newText;
    }
    if (child is ZplBarcode) {
      // Inherit column's alignment if child doesn't have its own alignment
      final childAlignment = child.alignment ?? alignment;

      final newBarcode = ZplBarcode(
        x: 0, // Always use x: 0 to allow alignment logic to work
        y: newY,
        data: child.data,
        type: child.type,
        height: child.height,
        orientation: child.orientation,
        printInterpretationLine: child.printInterpretationLine,
        printInterpretationLineAbove: child.printInterpretationLineAbove,
        moduleWidth: child.moduleWidth,
        wideBarToNarrowBarRatio: child.wideBarToNarrowBarRatio,
        alignment: childAlignment, // Use inherited or child's alignment
      );

      // Pass configuration to the new barcode instance
      if (_configuration != null) {
        newBarcode.setConfiguration(_configuration!);
      }

      return newBarcode;
    }
    if (child is ZplSeparator) {
      final newSeparator = ZplSeparator(
        x: 0, // Always use x: 0 for layout consistency
        y: newY,
        type: child.type,
        character: child.character,
        thickness: child.thickness,
        orientation: child.orientation,
        paddingLeft: child.paddingLeft,
        paddingRight: child.paddingRight,
        paddingTop: child.paddingTop,
        paddingBottom: child.paddingBottom,
        length: child.length,
        fontHeight: child.fontHeight,
        fontWidth: child.fontWidth,
      );

      // Pass configuration to the new separator instance
      if (_configuration != null) {
        newSeparator.setConfiguration(_configuration!);
      }

      return newSeparator;
    }
    if (child is ZplImage) {
      return ZplImage(
        x: newX,
        y: newY,
        image: child.image,
        graphicName: child.graphicName,
      );
    }
    if (child is ZplBox) {
      return ZplBox(
        x: newX,
        y: newY,
        width: child.width,
        height: child.height,
        borderThickness: child.borderThickness,
        cornerRounding: child.cornerRounding,
      );
    }
    if (child is ZplRow) {
      return ZplRow(
        x: newX,
        y: newY,
        children: child.children,
        spacing: child.spacing,
        alignment: child.alignment,
      );
    }
    return child; // Return unchanged if type is not recognized
  }

  @override
  int calculateWidth(ZplConfiguration? config) {
    // For columns, return the maximum width of any child
    int maxWidth = 0;
    for (final child in children) {
      final childWidth = child.calculateWidth(config);
      if (childWidth > maxWidth) {
        maxWidth = childWidth;
      }
    }
    return maxWidth;
  }
}
