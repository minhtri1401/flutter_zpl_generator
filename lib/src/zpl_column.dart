import 'zpl_command_base.dart';
import 'zpl_text.dart';
import 'zpl_barcode.dart';
import 'zpl_image.dart';
import 'zpl_box.dart';
import 'zpl_row.dart';
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
      // Calculate aligned X position based on alignment and configuration
      final alignedX = _calculateAlignedX(child);

      // Create a new instance of the child with updated coordinates
      final updatedChild = _updateChildPosition(child, alignedX, currentY);
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
      return element.fontHeight ?? 12;
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
    return 20; // Default fallback
  }

  ZplCommand _updateChildPosition(ZplCommand child, int newX, int newY) {
    if (child is ZplText) {
      return ZplText(
        x: newX,
        y: newY,
        text: child.text,
        font: child.font,
        fontHeight: child.fontHeight,
        fontWidth: child.fontWidth,
        orientation: child.orientation,
      );
    }
    if (child is ZplBarcode) {
      return ZplBarcode(
        x: newX,
        y: newY,
        data: child.data,
        type: child.type,
        height: child.height,
        orientation: child.orientation,
        printInterpretationLine: child.printInterpretationLine,
        printInterpretationLineAbove: child.printInterpretationLineAbove,
        moduleWidth: child.moduleWidth,
        wideBarToNarrowBarRatio: child.wideBarToNarrowBarRatio,
      );
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
