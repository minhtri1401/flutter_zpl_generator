import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  const config = ZplConfiguration();

  group('ZplTextBlock', () {
    test('ZplTextBlock generates ^FO^TB^FD^FS', () {
      final tb = ZplTextBlock(
        x: 10,
        y: 20,
        text: 'Hello World',
        maxWidth: 200,
        maxHeight: 100,
      );
      final zpl = tb.toZpl(config);
      expect(zpl, equals('^FO10,20^TBN,200,100^FDHello World^FS\n'));
    });

    test('ZplTextBlock with custom orientation uses orientation parameter', () {
      final tb = ZplTextBlock(
        x: 0,
        y: 0,
        text: 'Test',
        orientation: 'R',
        maxWidth: 100,
        maxHeight: 50,
      );
      final zpl = tb.toZpl(config);
      expect(zpl, equals('^FO0,0^TBR,100,50^FDTest^FS\n'));
    });

    test('ZplTextBlock calculateWidth returns maxWidth', () {
      final tb = ZplTextBlock(
        x: 0,
        y: 0,
        text: 'Text',
        maxWidth: 250,
        maxHeight: 150,
      );
      expect(tb.calculateWidth(config), 250);
    });

    test('ZplTextBlock with inverted orientation', () {
      final tb = ZplTextBlock(
        x: 50,
        y: 50,
        text: 'Inverted',
        orientation: 'I',
        maxWidth: 100,
        maxHeight: 100,
      );
      final zpl = tb.toZpl(config);
      expect(zpl, equals('^FO50,50^TBI,100,100^FDInverted^FS\n'));
    });

    test('ZplTextBlock with bottom-up orientation', () {
      final tb = ZplTextBlock(
        x: 0,
        y: 0,
        text: 'BottomUp',
        orientation: 'B',
        maxWidth: 100,
        maxHeight: 100,
      );
      final zpl = tb.toZpl(config);
      expect(zpl, equals('^FO0,0^TBB,100,100^FDBottomUp^FS\n'));
    });
  });

  group('ZplAdvancedTextProperties', () {
    test('ZplAdvancedTextProperties with no parameters generates ^PA0', () {
      final atp = const ZplAdvancedTextProperties();
      // When all params are null, defaults to '0' for defaultGlyph
      expect(atp.toZpl(config), equals('^PA0\n'));
    });

    test(
      'ZplAdvancedTextProperties with defaultGlyph generates ^PA with glyph',
      () {
        final atp = const ZplAdvancedTextProperties(defaultGlyph: 32);
        expect(atp.toZpl(config), equals('^PA32\n'));
      },
    );

    test('ZplAdvancedTextProperties with bidi true generates ^PA with 1', () {
      final atp = const ZplAdvancedTextProperties(bidi: true);
      expect(atp.toZpl(config), equals('^PA0,1\n'));
    });

    test('ZplAdvancedTextProperties with bidi false generates ^PA with 0', () {
      final atp = const ZplAdvancedTextProperties(bidi: false);
      expect(atp.toZpl(config), equals('^PA0,0\n'));
    });

    test('ZplAdvancedTextProperties with charShaping true', () {
      final atp = const ZplAdvancedTextProperties(charShaping: true);
      expect(atp.toZpl(config), equals('^PA0,,1\n'));
    });

    test('ZplAdvancedTextProperties with charShaping false', () {
      final atp = const ZplAdvancedTextProperties(charShaping: false);
      expect(atp.toZpl(config), equals('^PA0,,0\n'));
    });

    test('ZplAdvancedTextProperties with openTypeSupport true', () {
      final atp = const ZplAdvancedTextProperties(openTypeSupport: true);
      expect(atp.toZpl(config), equals('^PA0,,,1\n'));
    });

    test('ZplAdvancedTextProperties with openTypeSupport false', () {
      final atp = const ZplAdvancedTextProperties(openTypeSupport: false);
      expect(atp.toZpl(config), equals('^PA0,,,0\n'));
    });

    test('ZplAdvancedTextProperties with all parameters set', () {
      final atp = const ZplAdvancedTextProperties(
        defaultGlyph: 33,
        bidi: true,
        charShaping: true,
        openTypeSupport: false,
      );
      expect(atp.toZpl(config), equals('^PA33,1,1,0\n'));
    });

    test('ZplAdvancedTextProperties calculateWidth returns 0', () {
      final atp = const ZplAdvancedTextProperties();
      expect(atp.calculateWidth(config), 0);
    });

    test('ZplAdvancedTextProperties with mixed parameters', () {
      final atp = const ZplAdvancedTextProperties(
        bidi: true,
        openTypeSupport: true,
      );
      expect(atp.toZpl(config), equals('^PA0,1,,1\n'));
    });

    test('ZplAdvancedTextProperties trims trailing empty parameters', () {
      final atp = const ZplAdvancedTextProperties(
        defaultGlyph: 50,
        bidi: null,
        charShaping: null,
        openTypeSupport: null,
      );
      // Only defaultGlyph is set
      expect(atp.toZpl(config), equals('^PA50\n'));
    });
  });
}
