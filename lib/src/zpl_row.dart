import 'zpl_command_base.dart';
import 'zpl_text.dart';
import 'zpl_barcode.dart';
import 'zpl_image.dart';
import 'zpl_box.dart';
import 'zpl_column.dart';
import 'zpl_configuration.dart';
import 'enums.dart';

/// A layout helper to arrange multiple [ZplCommand] objects horizontally in a row.
/// This class does not generate ZPL itself but modifies its children to align them.
/// It can optionally use configuration context for advanced alignment features.
class ZplRow extends ZplCommand {
  final int x;
  final int y;
  final List<ZplCommand> children;
  final int spacing;
  final ZplAlignment alignment;

  /// Optional configuration context for advanced alignment features
  ZplConfiguration? _configuration;

  ZplRow({
    this.x = 0,
    this.y = 0,
    required this.children,
    this.spacing = 10,
    this.alignment = ZplAlignment.left,
  }) {
    // Validate that children don't contain nested ZplRows
    for (final child in children) {
      if (child is ZplRow) {
        throw ArgumentError(
          'ZplRow cannot contain another ZplRow. Nested rows are not supported.',
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

    // Calculate starting X position based on alignment and configuration
    var currentX = _calculateAlignedStartX();

    for (var child in children) {
      // Create a new instance of the child with updated coordinates
      final updatedChild = _updateChildPosition(child, currentX, y);
      sb.write(updatedChild.toZpl());

      // Calculate width based on element type
      final elementWidth = _calculateElementWidth(child);
      currentX += elementWidth + spacing;
    }

    return sb.toString();
  }

  /// Calculate the starting X position based on alignment and available width
  int _calculateAlignedStartX() {
    if (alignment == ZplAlignment.left || _configuration == null) {
      return x; // Default to left alignment
    }

    final labelWidth =
        _configuration!.printWidth ?? 406; // Default to 2" at 203dpi
    final totalRowWidth = _calculateTotalRowWidth();

    int calculatedX;
    switch (alignment) {
      case ZplAlignment.center:
        calculatedX = x + ((labelWidth - totalRowWidth) ~/ 2);
        break;
      case ZplAlignment.right:
        calculatedX = x + (labelWidth - totalRowWidth);
        break;
      case ZplAlignment.left:
        calculatedX = x;
        break;
    }

    // Ensure X position is never negative and doesn't exceed label width
    return calculatedX.clamp(0, labelWidth - 1);
  }

  /// Calculate the total width of all children including spacing
  int _calculateTotalRowWidth() {
    int totalWidth = 0;
    for (int i = 0; i < children.length; i++) {
      totalWidth += _calculateElementWidth(children[i]);
      if (i < children.length - 1) {
        totalWidth += spacing;
      }
    }
    return totalWidth;
  }

  /// Calculate estimated width of an element
  /// Note: This is a rough estimation. For precise positioning,
  /// you would need to measure actual rendered dimensions.
  int _calculateElementWidth(ZplCommand element) {
    return element.calculateWidth(_configuration);
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
    if (child is ZplColumn) {
      return ZplColumn(
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
    // For rows, return the total width of all children plus spacing
    return _calculateTotalRowWidth();
  }
}
