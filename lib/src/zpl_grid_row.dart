import 'zpl_command_base.dart';
import 'zpl_grid_col.dart';
import 'zpl_configuration.dart';
import 'zpl_text.dart';
import 'zpl_barcode.dart';
import 'zpl_image.dart';
import 'zpl_box.dart';
import 'zpl_separator.dart';

/// Creates a row with a 12-unit grid system for structured layouts.
///
/// Columns are defined as fractions of 12 units. Automatically calculates
/// positioning and available width for each column based on the label's
/// total print width.
class ZplGridRow extends ZplCommand {
  /// The x-axis position of the grid row.
  final int x;

  /// The y-axis position of the grid row.
  final int y;

  /// List of columns that make up this row.
  final List<ZplGridCol> children;

  /// Spacing between columns in dots (default: 0).
  final int columnSpacing;

  ZplGridRow({
    this.x = 0,
    this.y = 0,
    required this.children,
    this.columnSpacing = 0,
  }) {
    _validateColumns();
  }

  /// Validate that columns don't exceed 12 units total.
  void _validateColumns() {
    int totalUnits = 0;
    for (final col in children) {
      totalUnits += col.width + col.offset;
    }
    if (totalUnits > 12) {
      throw ArgumentError(
        'Total column widths and offsets ($totalUnits) exceed 12 units. '
        'Reduce column widths or offsets.',
      );
    }
  }

  @override
  String toZpl(ZplConfiguration context) {
    final labelWidth = context.printWidth ?? 406;
    final sb = StringBuffer();

    final totalSpacing = (children.length - 1) * columnSpacing;
    final availableWidth = labelWidth - totalSpacing;
    final unitWidth = availableWidth / 12.0;

    int actualX = x;

    for (int i = 0; i < children.length; i++) {
      final col = children[i];

      actualX += (col.offset * unitWidth).round();
      final colWidthDots = (col.width * unitWidth).round();

      final updatedChild = _updateChildPosition(
        col.child,
        actualX,
        y,
        colWidthDots,
      );

      sb.write(updatedChild.toZpl(context));

      actualX += colWidthDots;
      if (i < children.length - 1) {
        actualX += columnSpacing;
      }
    }

    return sb.toString();
  }

  /// Update child position with actual x coordinate and maxWidth constraint.
  ZplCommand _updateChildPosition(
    ZplCommand child,
    int newX,
    int newY,
    int availableWidth,
  ) {
    if (child is ZplText) {
      return ZplText(
        x: newX,
        y: newY,
        text: child.text,
        font: child.font,
        fontAlias: child.fontAlias,
        fontHeight: child.fontHeight,
        fontWidth: child.fontWidth,
        orientation: child.orientation,
        alignment: child.alignment,
        paddingLeft: child.paddingLeft,
        paddingRight: child.paddingRight,
        maxLines: child.maxLines,
        lineSpacing: child.lineSpacing,
        customFont: child.customFont,
        maxWidth: availableWidth,
        reversePrint: child.reversePrint,
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
        alignment: child.alignment,
        maxWidth: availableWidth,
      );
    }

    if (child is ZplSeparator) {
      return ZplSeparator(
        x: newX,
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
        maxWidth: availableWidth,
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
        reversePrint: child.reversePrint,
      );
    }

    return child;
  }

  @override
  int calculateWidth(ZplConfiguration config) {
    return config.printWidth ?? 406;
  }

  /// Calculate the height of the grid row (max height of all columns).
  int calculateHeight(ZplConfiguration config) {
    if (children.isEmpty) return 0;

    int maxHeight = 0;
    for (final col in children) {
      final childHeight = _calculateChildHeight(col.child, config);
      if (childHeight > maxHeight) maxHeight = childHeight;
    }

    return maxHeight;
  }

  /// Calculate height of a child element.
  int _calculateChildHeight(ZplCommand child, ZplConfiguration config) {
    if (child is ZplText) return child.fontHeight ?? 12;
    if (child is ZplBarcode) return child.height;
    if (child is ZplBox) return child.height;
    if (child is ZplImage) {
      try {
        return child.height;
      } catch (e) {
        return 60;
      }
    }
    if (child is ZplSeparator) return child.calculateHeight(config);
    return 20;
  }
}
