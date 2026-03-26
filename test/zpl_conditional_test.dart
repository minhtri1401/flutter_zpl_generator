import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('ZplConditional Tests', () {
    test('renders child when condition is true', () async {
      final zpl = ZplConditional(
        condition: true,
        child: ZplText(x: 10, y: 10, text: 'Visible Text'),
      );

      final generated = zpl.toZpl(const ZplConfiguration());
      expect(generated, contains('Visible Text'));
    });

    test('returns empty string when condition is false', () async {
      final zpl = ZplConditional(
        condition: false,
        child: ZplText(x: 10, y: 10, text: 'Hidden Text'),
      );

      final generated = zpl.toZpl(const ZplConfiguration());
      expect(generated, isEmpty);
    });

    test('inside ZplColumn skips height logic when false', () async {
      final column = ZplColumn(
        spacing: 10,
        y: 0,
        children: [
          ZplText(text: 'Item 1'),
          ZplConditional(
            condition: false, // Should take 0 height and output nothing
            child: ZplText(text: 'Item 2 (Hidden)'),
          ),
          ZplText(text: 'Item 3'),
        ],
      );

      final generator = ZplGenerator(
        config: const ZplConfiguration(),
        commands: [column],
      );

      final zpl = await generator.build();
      print(zpl);
      
      expect(zpl, contains('Item 1'));
      expect(zpl, isNot(contains('Item 2 (Hidden)')));
      expect(zpl, contains('Item 3'));
      
      final item1Match = zpl.contains('^FO0,0\n^A0N,,\n^FDItem 1^FS');
      final item3Match = zpl.contains('^FO0,32\n^A0N,,\n^FDItem 3^FS');
      
      expect(item1Match, isTrue, reason: 'Item 1 should be at y=0');
      expect(item3Match, isTrue, reason: 'Item 3 should be at y=32');
    });

    test('inside ZplGridRow skips height calculations when false', () async {
       final row = ZplGridRow(
         y: 100,
         children: [
           ZplGridCol(
             width: 12, 
             child: ZplConditional(
               condition: false,
               child: ZplText(text: 'Hidden Grid Child', fontHeight: 50),
             ),
           )
         ]
       );

       final height = row.calculateHeight(const ZplConfiguration());
       expect(height, equals(0)); // Height must be exactly 0, not 50.
    });
  });
}
