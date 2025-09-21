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
/// This class implements a responsive grid system where columns are defined
/// as fractions of 12 units. It automatically calculates positioning and
/// available width for each column based on the label's total print width.
///
/// Example usage:
/// ```dart
/// ZplGridRow(
///   y: 100,
///   children: [
///     ZplGridCol(width: 6, child: ZplText(text: 'Product Name')),
///     ZplGridCol(width: 2, child: ZplText(text: 'Qty', alignment: ZplAlignment.center)),
///     ZplGridCol(width: 2, child: ZplText(text: 'Price', alignment: ZplAlignment.right)),
///     ZplGridCol(width: 2, child: ZplText(text: 'Total', alignment: ZplAlignment.right)),
///   ],
/// )
/// ```
class ZplGridRow extends ZplCommand {
  /// The x-axis position of the grid row.
  final int x;

  /// The y-axis position of the grid row.
  final int y;

  /// List of columns that make up this row.
  final List<ZplGridCol> children;

  /// Spacing between columns in dots (default: 0).
  final int columnSpacing;

  /// Optional configuration context for automatic sizing
  ZplConfiguration? _configuration;

  ZplGridRow({
    this.x = 0,
    this.y = 0,
    required this.children,
    this.columnSpacing = 0,
  }) {
    _validateColumns();
  }

  /// Set configuration context for automatic sizing
  void setConfiguration(ZplConfiguration config) {
    _configuration = config;
  }

  /// Validate that columns don't exceed 12 units total
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
  String toZpl() {
    if (_configuration == null) {
      throw StateError(
        'ZplGridRow requires ZplConfiguration context. '
        'Ensure it\'s included in your ZplGenerator commands.',
      );
    }

    final labelWidth = _configuration!.printWidth ?? 406;
    final sb = StringBuffer();

    // Calculate the width of a single grid unit in dots
    final totalSpacing = (children.length - 1) * columnSpacing;
    final availableWidth = labelWidth - totalSpacing;
    final unitWidth = availableWidth / 12.0;

    int currentGridPosition = 0;
    int actualX = x;

    for (int i = 0; i < children.length; i++) {
      final col = children[i];

      // Handle offset (empty space before this column)
      currentGridPosition += col.offset;
      actualX += (col.offset * unitWidth).round();

      // Calculate column width in dots
      final colWidthDots = (col.width * unitWidth).round();

      // Create updated child with calculated position and context
      final updatedChild = _updateChildPosition(
        col.child,
        actualX,
        y,
        colWidthDots,
      );

      // Generate ZPL for this column
      sb.write(updatedChild.toZpl());

      // Move to next position
      currentGridPosition += col.width;
      actualX += colWidthDots;

      // Add column spacing (except for last column)
      if (i < children.length - 1) {
        actualX += columnSpacing;
      }
    }

    return sb.toString();
  }

  /// Update child position and propagate configuration
  ZplCommand _updateChildPosition(
    ZplCommand child,
    int newX,
    int newY,
    int availableWidth,
  ) {
    if (child is ZplText) {
      final newText = ZplText(
        x: 0, // Use 0 to allow ^FB alignment to work with available width
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
      );

      // Create a temporary configuration with the column width for this text
      if (_configuration != null) {
        final columnConfig = ZplConfiguration(
          printWidth: availableWidth,
          labelLength: _configuration!.labelLength,
          printDensity: _configuration!.printDensity,
        );
        newText.setConfiguration(columnConfig);
      }

      // Manually set the actual position after alignment calculation
      return _PositionWrapper(newText, newX);
    }

    if (child is ZplBarcode) {
      final newBarcode = ZplBarcode(
        x: 0, // Use 0 to allow alignment logic to work
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
      );

      // Create a temporary configuration with the column width
      if (_configuration != null) {
        final columnConfig = ZplConfiguration(
          printWidth: availableWidth,
          labelLength: _configuration!.labelLength,
          printDensity: _configuration!.printDensity,
        );
        newBarcode.setConfiguration(columnConfig);
      }

      return _PositionWrapper(newBarcode, newX);
    }

    if (child is ZplSeparator) {
      final newSeparator = ZplSeparator(
        x: 0,
        y: newY,
        type: child.type,
        character: child.character,
        thickness: child.thickness,
        orientation: child.orientation,
        paddingLeft: child.paddingLeft,
        paddingRight: child.paddingRight,
        paddingTop: child.paddingTop,
        paddingBottom: child.paddingBottom,
        length: availableWidth, // Set specific length for column width
        fontHeight: child.fontHeight,
        fontWidth: child.fontWidth,
      );

      if (_configuration != null) {
        final columnConfig = ZplConfiguration(
          printWidth: availableWidth,
          labelLength: _configuration!.labelLength,
          printDensity: _configuration!.printDensity,
        );
        newSeparator.setConfiguration(columnConfig);
      }

      return _PositionWrapper(newSeparator, newX);
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

    // For unknown types, just update position
    return child;
  }

  @override
  int calculateWidth(ZplConfiguration? config) {
    // Grid rows always use the full label width
    return config?.printWidth ?? 406;
  }

  /// Calculate the height of the grid row (max height of all columns)
  int calculateHeight(ZplConfiguration? config) {
    if (children.isEmpty) return 0;

    int maxHeight = 0;
    for (final col in children) {
      final childHeight = _calculateChildHeight(col.child, config);
      if (childHeight > maxHeight) {
        maxHeight = childHeight;
      }
    }

    return maxHeight;
  }

  /// Calculate height of a child element
  int _calculateChildHeight(ZplCommand child, ZplConfiguration? config) {
    if (child is ZplText) {
      return child.fontHeight ?? 12;
    }
    if (child is ZplBarcode) {
      return child.height;
    }
    if (child is ZplBox) {
      return child.height;
    }
    if (child is ZplImage) {
      try {
        return child.height;
      } catch (e) {
        return 60; // Fallback
      }
    }
    if (child is ZplSeparator) {
      return child.calculateHeight(config);
    }

    return 20; // Default fallback
  }
}

/// Internal wrapper to handle positioning after alignment calculations
class _PositionWrapper extends ZplCommand {
  final ZplCommand _child;
  final int _actualX;

  _PositionWrapper(this._child, this._actualX);

  @override
  String toZpl() {
    final childZpl = _child.toZpl();

    // Replace the first ^FO0, with ^FO{actualX},
    return childZpl.replaceFirst('^FO0,', '^FO$_actualX,');
  }

  @override
  int calculateWidth(ZplConfiguration? config) {
    return _child.calculateWidth(config);
  }
}
