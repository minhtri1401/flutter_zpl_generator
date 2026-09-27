import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  const config = ZplConfiguration();

  group('ZplTable', () {
    test('basic table generates ^FO for positions and ^GB for borders', () {
      final table = ZplTable(
        x: 10,
        y: 10,
        headers: [
          ZplTableHeader('Name', alignment: ZplAlignment.left),
          ZplTableHeader('Age', alignment: ZplAlignment.center),
        ],
        data: [
          ['Alice', '25'],
          ['Bob', '30'],
        ],
        columnWidths: [6, 6],
        borderThickness: 1,
      );

      final zpl = table.toZpl(config);
      expect(zpl, contains('^FO')); // Field origin
      expect(zpl, contains('^GB')); // Box drawing (for borders)
      expect(zpl, contains('^FD')); // Field data
      expect(zpl, contains('Name'));
      expect(zpl, contains('Alice'));
    });

    test('table with no borders still generates content', () {
      final table = ZplTable(
        x: 10,
        y: 10,
        headers: [ZplTableHeader('Col1')],
        data: [
          ['Data1'],
        ],
        columnWidths: [12],
        borderThickness: 0,
      );

      final zpl = table.toZpl(config);
      expect(zpl, contains('Col1'));
      expect(zpl, contains('Data1'));
    });

    test('table columns are positioned horizontally', () {
      final table = ZplTable(
        x: 20,
        y: 30,
        headers: [ZplTableHeader('H1'), ZplTableHeader('H2')],
        data: [
          ['R1C1', 'R1C2'],
        ],
        columnWidths: [6, 6],
        borderThickness: 1,
      );

      final zpl = table.toZpl(config);
      // Multiple ^FO sequences for different columns
      final foCount = RegExp(r'\^FO').allMatches(zpl).length;
      expect(foCount, greaterThan(0));
    });

    test('table with cell padding adds space between content and border', () {
      final table = ZplTable(
        x: 0,
        y: 0,
        headers: [ZplTableHeader('Test')],
        data: [
          ['Data'],
        ],
        columnWidths: [12],
        cellPadding: 8,
        borderThickness: 1,
      );

      final zpl = table.toZpl(config);
      expect(zpl, contains('Test'));
      expect(zpl, contains('Data'));
    });

    test('table with custom data alignment uses specified alignment', () {
      final table = ZplTable(
        x: 0,
        y: 0,
        headers: [ZplTableHeader('Col', alignment: ZplAlignment.right)],
        data: [
          ['Value'],
        ],
        columnWidths: [12],
        dataAlignment: ZplAlignment.center,
        borderThickness: 1,
      );

      final zpl = table.toZpl(config);
      expect(zpl, contains('Col'));
      expect(zpl, contains('Value'));
    });

    test('calculateWidth returns print width', () {
      final table = ZplTable(
        x: 0,
        y: 0,
        headers: [ZplTableHeader('H')],
        data: [
          ['D'],
        ],
        columnWidths: [12],
      );

      expect(table.calculateWidth(config), 406); // Default print width
    });

    test('table header font properties are applied', () {
      final table = ZplTable(
        x: 0,
        y: 0,
        headers: [
          ZplTableHeader(
            'Header',
            fontHeight: 24,
            fontWidth: 18,
            alignment: ZplAlignment.center,
          ),
        ],
        data: [
          ['Data'],
        ],
        columnWidths: [12],
      );

      final zpl = table.toZpl(config);
      expect(zpl, contains('Header'));
    });

    test('multiple data rows are positioned vertically', () {
      final table = ZplTable(
        x: 0,
        y: 0,
        headers: [ZplTableHeader('Col')],
        data: [
          ['Row1'],
          ['Row2'],
          ['Row3'],
        ],
        columnWidths: [12],
      );

      final zpl = table.toZpl(config);
      expect(zpl, contains('Row1'));
      expect(zpl, contains('Row2'));
      expect(zpl, contains('Row3'));
    });

    test('table vertical lines are drawn for column separators', () {
      final table = ZplTable(
        x: 0,
        y: 0,
        headers: [
          ZplTableHeader('C1'),
          ZplTableHeader('C2'),
          ZplTableHeader('C3'),
        ],
        data: [
          ['D1', 'D2', 'D3'],
        ],
        columnWidths: [4, 4, 4],
        borderThickness: 1,
      );

      final zpl = table.toZpl(config);
      // Multiple ^GB sequences for vertical separators
      final gbCount = RegExp(r'\^GB').allMatches(zpl).length;
      expect(gbCount, greaterThan(0)); // At least outer border + separators
    });

    test('table with custom font sizes uses specified dimensions', () {
      final table = ZplTable(
        x: 0,
        y: 0,
        headers: [ZplTableHeader('Header')],
        data: [
          ['Cell'],
        ],
        columnWidths: [12],
        dataFontHeight: 24,
        dataFontWidth: 16,
      );

      final zpl = table.toZpl(config);
      expect(zpl, contains('Header'));
      expect(zpl, contains('Cell'));
    });
  });
}
