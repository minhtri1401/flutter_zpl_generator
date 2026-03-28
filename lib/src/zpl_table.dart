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
class ZplTable extends ZplCommand {
  /// The x-axis position of the table.
  final int x;

  /// The y-axis position of the table.
  final int y;

  /// The list of headers for the table.
  final List<ZplTableHeader> headers;

  /// The table data as a list of rows, each row is a list of strings.
  final List<List<String>> data;

  /// The width of each column in grid units (1-12).
  final List<int> columnWidths;

  /// The thickness of the border lines in dots. Set to 0 for no border.
  final int borderThickness;

  /// The padding inside each cell in dots.
  final int cellPadding;

  /// Font height for data cells.
  final int dataFontHeight;

  /// Font width for data cells.
  final int dataFontWidth;

  /// Alignment for data cells.
  final ZplAlignment dataAlignment;

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
    final totalWidth = columnWidths.fold(0, (sum, w) => sum + w);
    assert(totalWidth <= 12, 'Total column widths cannot exceed 12 units.');
  }

  @override
  String toZpl(ZplConfiguration context) {
    final sb = StringBuffer();
    final labelWidth = context.printWidth ?? 406;
    final tableWidth = labelWidth;
    final rowHeight = _calculateRowHeight();
    final headerHeight = rowHeight;
    final totalDataHeight = data.length * rowHeight;

    final borderSpacing =
        borderThickness > 0 ? (data.length + 1) * borderThickness : 0;
    final totalTableHeight = headerHeight + totalDataHeight + borderSpacing;

    if (borderThickness > 0) {
      sb.write(
        _drawTableBorders(tableWidth, totalTableHeight, rowHeight, context),
      );
    }

    final adjustedConfig = _buildAdjustedConfig(context);
    final headerRow = _createHeaderRow(adjustedConfig);
    sb.write(headerRow.toZpl(adjustedConfig));

    for (int i = 0; i < data.length; i++) {
      final rowY = y +
          headerHeight +
          (i * rowHeight) +
          (borderThickness > 0 ? (i + 1) * borderThickness : 0);

      final dataRow = _createDataRow(data[i], rowY, adjustedConfig);
      sb.write(dataRow.toZpl(adjustedConfig));
    }

    return sb.toString();
  }

  /// Build a config with width adjusted for borders.
  ZplConfiguration _buildAdjustedConfig(ZplConfiguration context) {
    final adjustedWidth = (context.printWidth ?? 406) -
        (borderThickness > 0 ? 2 * borderThickness : 0);
    return ZplConfiguration(
      darkness: context.darkness,
      labelLength: context.labelLength,
      labelHomeX: context.labelHomeX,
      labelHomeY: context.labelHomeY,
      printWidth: adjustedWidth,
      printSpeed: context.printSpeed,
      printMode: context.printMode,
      mediaType: context.mediaType,
      printOrientation: context.printOrientation,
      internationalEncoding: context.internationalEncoding,
      printDensity: context.printDensity,
    );
  }

  /// Calculate the height of a single row based on font sizes and padding.
  int _calculateRowHeight() {
    int maxHeaderFontHeight = 0;
    for (final header in headers) {
      final h = header.fontHeight ?? 20;
      if (h > maxHeaderFontHeight) maxHeaderFontHeight = h;
    }
    final maxFontHeight = [
      maxHeaderFontHeight,
      dataFontHeight,
    ].reduce((a, b) => a > b ? a : b);
    return maxFontHeight + (2 * cellPadding);
  }

  /// Create the header row.
  ZplGridRow _createHeaderRow(ZplConfiguration context) {
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

    final contentX = x + (borderThickness > 0 ? borderThickness : 0);
    final contentY =
        y + (borderThickness > 0 ? borderThickness : 0) + cellPadding;

    return ZplGridRow(x: contentX, y: contentY, children: headerChildren);
  }

  /// Create a data row.
  ZplGridRow _createDataRow(
    List<String> rowData,
    int rowY,
    ZplConfiguration context,
  ) {
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

    final contentX = x + (borderThickness > 0 ? borderThickness : 0);
    final contentY = rowY + cellPadding;

    return ZplGridRow(x: contentX, y: contentY, children: dataChildren);
  }

  /// Get the alignment for a specific column.
  ZplAlignment _getColumnAlignment(int columnIndex) {
    if (columnIndex < headers.length) {
      return headers[columnIndex].alignment;
    }
    return dataAlignment;
  }

  /// Draw all table borders (outer border, horizontal lines, vertical lines).
  String _drawTableBorders(
    int tableWidth,
    int totalTableHeight,
    int rowHeight,
    ZplConfiguration context,
  ) {
    final sb = StringBuffer();

    sb.write(
      ZplBox(
        x: x,
        y: y,
        width: tableWidth,
        height: totalTableHeight,
        borderThickness: borderThickness,
      ).toZpl(context),
    );

    sb.write(
      ZplBox(
        x: x,
        y: y + rowHeight,
        width: tableWidth,
        height: borderThickness,
        borderThickness: borderThickness,
      ).toZpl(context),
    );

    for (int i = 1; i < data.length; i++) {
      final lineY = y + rowHeight + (i * rowHeight) + (i * borderThickness);
      sb.write(
        ZplBox(
          x: x,
          y: lineY,
          width: tableWidth,
          height: borderThickness,
          borderThickness: borderThickness,
        ).toZpl(context),
      );
    }

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
          ).toZpl(context),
        );
      }
    }

    return sb.toString();
  }

  @override
  int calculateWidth(ZplConfiguration config) {
    return config.printWidth ?? 406;
  }

  /// Calculate the total height of the table.
  int calculateHeight(ZplConfiguration config) {
    final rowHeight = _calculateRowHeight();
    return rowHeight * (data.length + 1);
  }
}
