import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'zpl_text.dart';
import 'zpl_grid_row.dart';
import 'zpl_grid_col.dart';
import 'zpl_box.dart';
import 'enums.dart';

/// A helper class to define the content and styling of a table header.
class ZplTableHeader {
  /// The text content of the header.
  final String text;

  /// The alignment of the header text within its cell.
  final ZplAlignment alignment;

  /// The font height for the header text.
  final int? fontHeight;

  /// The font width for the header text.
  final int? fontWidth;

  ZplTableHeader(
    this.text, {
    this.alignment = ZplAlignment.left,
    this.fontHeight,
    this.fontWidth,
  });
}

/// A highly configurable widget that generates a table with headers,
/// data rows, and borders using ZPL commands.
///
/// This widget provides a high-level abstraction for creating structured
/// tables with automatic border drawing, cell padding, and alignment.
///
/// Example usage:
/// ```dart
/// ZplTable(
///   y: 100,
///   columnWidths: [6, 2, 2, 2], // 12-column grid widths
///   headers: [
///     ZplTableHeader('Item', alignment: ZplAlignment.left),
///     ZplTableHeader('Qty', alignment: ZplAlignment.center),
///     ZplTableHeader('Price', alignment: ZplAlignment.right),
///     ZplTableHeader('Total', alignment: ZplAlignment.right),
///   ],
///   data: [
///     ['V-Neck T-Shirt', '1', '10.00', '10.00'],
///     ['Polo Shirt', '2', '25.50', '51.00'],
///   ],
/// )
/// ```
class ZplTable extends ZplCommand {
  /// The x-axis position of the table.
  final int x;

  /// The y-axis position of the table.
  final int y;

  /// The list of headers for the table.
  final List<ZplTableHeader> headers;

  /// The table data, represented as a list of rows, where each row is a
  /// list of strings that will be converted to ZplText commands.
  final List<List<String>> data;

  /// The width of each column in grid units (1-12). The length of this list
  /// must match the number of columns.
  final List<int> columnWidths;

  /// The thickness of the border lines in dots. Set to 0 for no border.
  final int borderThickness;

  /// The padding inside each cell in dots.
  final int cellPadding;

  /// Font height for data cells (headers use their own fontHeight).
  final int dataFontHeight;

  /// Font width for data cells (headers use their own fontWidth).
  final int dataFontWidth;

  /// Alignment for data cells (headers use their own alignment).
  final ZplAlignment dataAlignment;

  /// Optional configuration context for automatic sizing
  ZplConfiguration? _configuration;

  ZplTable({
    this.x = 0,
    this.y = 0,
    required this.headers,
    required this.data,
    required this.columnWidths,
    this.borderThickness = 1,
    this.cellPadding = 4,
    this.dataFontHeight = 18,
    this.dataFontWidth = 13,
    this.dataAlignment = ZplAlignment.left,
  }) {
    assert(
      headers.length == columnWidths.length,
      'Number of headers must match number of column widths.',
    );
    for (var row in data) {
      assert(
        row.length == columnWidths.length,
        'Number of cells in each data row must match number of column widths.',
      );
    }

    // Validate column widths sum to 12 or less
    final totalWidth = columnWidths.fold(0, (sum, width) => sum + width);
    assert(totalWidth <= 12, 'Total column widths cannot exceed 12 units.');
  }

  /// Set configuration context for automatic sizing
  void setConfiguration(ZplConfiguration config) {
    _configuration = config;
  }

  @override
  String toZpl() {
    if (_configuration == null) {
      throw StateError(
        'ZplTable requires ZplConfiguration context. '
        'Ensure it\'s included in your ZplGenerator commands.',
      );
    }

    final sb = StringBuffer();
    final labelWidth = _configuration!.printWidth ?? 406;

    // Calculate table dimensions
    final tableWidth = labelWidth;
    final rowHeight = _calculateRowHeight();
    final headerHeight = rowHeight;
    final totalDataHeight = data.length * rowHeight;

    // Account for border thickness in total height
    final borderSpacing = borderThickness > 0
        ? (data.length + 1) *
              borderThickness // +1 for header separator
        : 0;
    final totalTableHeight = headerHeight + totalDataHeight + borderSpacing;

    // Draw outer border
    if (borderThickness > 0) {
      sb.write(_drawTableBorders(tableWidth, totalTableHeight, rowHeight));
    }

    // Generate header row
    final headerRow = _createHeaderRow();
    sb.write(headerRow.toZpl());

    // Generate data rows (account for borders between rows)
    for (int i = 0; i < data.length; i++) {
      // Calculate row Y position accounting for:
      // - Initial Y position
      // - Header height
      // - Previous rows
      // - Border lines between rows
      final rowY =
          y +
          headerHeight +
          (i * rowHeight) +
          (borderThickness > 0 ? (i + 1) * borderThickness : 0);

      final dataRow = _createDataRow(data[i], rowY);
      sb.write(dataRow.toZpl());
    }

    return sb.toString();
  }

  /// Calculate the height of a single row based on font sizes and padding
  int _calculateRowHeight() {
    // Use the maximum font height from headers and data, plus padding
    int maxHeaderFontHeight = 0;
    for (final header in headers) {
      final headerFontHeight = header.fontHeight ?? 20;
      if (headerFontHeight > maxHeaderFontHeight) {
        maxHeaderFontHeight = headerFontHeight;
      }
    }

    final maxFontHeight = [
      maxHeaderFontHeight,
      dataFontHeight,
    ].reduce((a, b) => a > b ? a : b);
    return maxFontHeight + (2 * cellPadding);
  }

  /// Create the header row using ZplGridRow and ZplGridCol
  ZplGridRow _createHeaderRow() {
    final headerChildren = <ZplGridCol>[];

    for (int i = 0; i < headers.length; i++) {
      final header = headers[i];
      headerChildren.add(
        ZplGridCol(
          width: columnWidths[i],
          child: ZplText(
            text: header.text,
            fontHeight: header.fontHeight ?? 20,
            fontWidth: header.fontWidth ?? 15,
            alignment: header.alignment,
            paddingLeft: cellPadding,
            paddingRight: cellPadding,
          ),
        ),
      );
    }

    // Adjust position for border thickness
    final contentX = x + (borderThickness > 0 ? borderThickness : 0);
    final contentY =
        y + (borderThickness > 0 ? borderThickness : 0) + cellPadding;

    final headerRow = ZplGridRow(
      x: contentX,
      y: contentY,
      children: headerChildren,
    );

    // Set configuration for the header row with adjusted width for borders
    if (_configuration != null) {
      final adjustedWidth =
          (_configuration!.printWidth ?? 406) -
          (borderThickness > 0 ? 2 * borderThickness : 0);
      final adjustedConfig = ZplConfiguration(
        printWidth: adjustedWidth,
        labelLength: _configuration!.labelLength,
        printDensity: _configuration!.printDensity,
      );
      headerRow.setConfiguration(adjustedConfig);
    }

    return headerRow;
  }

  /// Create a data row using ZplGridRow and ZplGridCol
  ZplGridRow _createDataRow(List<String> rowData, int rowY) {
    final dataChildren = <ZplGridCol>[];

    for (int i = 0; i < rowData.length; i++) {
      dataChildren.add(
        ZplGridCol(
          width: columnWidths[i],
          child: ZplText(
            text: rowData[i],
            fontHeight: dataFontHeight,
            fontWidth: dataFontWidth,
            alignment: _getColumnAlignment(i),
            paddingLeft: cellPadding,
            paddingRight: cellPadding,
          ),
        ),
      );
    }

    // Adjust position for border thickness
    // Note: rowY is already relative to table position, just need to add border offset
    final contentX = x + (borderThickness > 0 ? borderThickness : 0);
    final contentY = rowY + cellPadding;

    final dataRow = ZplGridRow(
      x: contentX,
      y: contentY,
      children: dataChildren,
    );

    // Set configuration for the data row with adjusted width for borders
    if (_configuration != null) {
      final adjustedWidth =
          (_configuration!.printWidth ?? 406) -
          (borderThickness > 0 ? 2 * borderThickness : 0);
      final adjustedConfig = ZplConfiguration(
        printWidth: adjustedWidth,
        labelLength: _configuration!.labelLength,
        printDensity: _configuration!.printDensity,
      );
      dataRow.setConfiguration(adjustedConfig);
    }

    return dataRow;
  }

  /// Get the alignment for a specific column (uses header alignment if available)
  ZplAlignment _getColumnAlignment(int columnIndex) {
    if (columnIndex < headers.length) {
      return headers[columnIndex].alignment;
    }
    return dataAlignment;
  }

  /// Draw all table borders (outer border, horizontal lines, vertical lines)
  String _drawTableBorders(
    int tableWidth,
    int totalTableHeight,
    int rowHeight,
  ) {
    final sb = StringBuffer();

    // Outer border
    sb.write(
      ZplBox(
        x: x,
        y: y,
        width: tableWidth,
        height: totalTableHeight,
        borderThickness: borderThickness,
      ).toZpl(),
    );

    // Horizontal line after header
    sb.write(
      ZplBox(
        x: x,
        y: y + rowHeight,
        width: tableWidth,
        height: borderThickness,
        borderThickness: borderThickness,
      ).toZpl(),
    );

    // Horizontal lines between data rows
    for (int i = 1; i < data.length; i++) {
      // Match the row positioning logic: account for border thickness
      final lineY = y + rowHeight + (i * rowHeight) + (i * borderThickness);
      sb.write(
        ZplBox(
          x: x,
          y: lineY,
          width: tableWidth,
          height: borderThickness,
          borderThickness: borderThickness,
        ).toZpl(),
      );
    }

    // Vertical lines between columns
    if (columnWidths.length > 1) {
      final unitWidth = tableWidth / 12.0;
      int currentGridPosition = 0;

      for (int i = 0; i < columnWidths.length - 1; i++) {
        currentGridPosition += columnWidths[i];
        final lineX = x + (currentGridPosition * unitWidth).round();

        sb.write(
          ZplBox(
            x: lineX,
            y: y,
            width: borderThickness,
            height: totalTableHeight,
            borderThickness: borderThickness,
          ).toZpl(),
        );
      }
    }

    return sb.toString();
  }

  @override
  int calculateWidth(ZplConfiguration? config) {
    return config?.printWidth ?? 406;
  }

  /// Calculate the total height of the table
  int calculateHeight(ZplConfiguration? config) {
    final rowHeight = _calculateRowHeight();
    return rowHeight * (data.length + 1); // +1 for header
  }
}
