import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  const config = ZplConfiguration();

  group('ZplSeparator', () {
    test('horizontal box separator generates ^GB (box drawing)', () {
      final sep = ZplSeparator(
        x: 0,
        y: 50,
        type: ZplSeparatorType.box,
        thickness: 2,
        orientation: ZplOrientation.normal,
        length: 100,
      );
      final zpl = sep.toZpl(config);
      expect(zpl, contains('^GB'));
      expect(zpl, contains('100,2'));
    });

    test('vertical box separator generates ^GB', () {
      final sep = ZplSeparator(
        x: 100,
        y: 0,
        type: ZplSeparatorType.box,
        thickness: 2,
        orientation: ZplOrientation.rotated90,
        length: 200,
      );
      final zpl = sep.toZpl(config);
      expect(zpl, contains('^GB'));
      expect(zpl, contains('2,200'));
    });

    test('character separator generates repeated characters', () {
      final sep = ZplSeparator(
        x: 0,
        y: 50,
        type: ZplSeparatorType.character,
        character: '-',
        orientation: ZplOrientation.normal,
        fontHeight: 12,
        fontWidth: 10,
        length: 100,
      );
      final zpl = sep.toZpl(config);
      expect(zpl, contains('-'));
      expect(zpl, contains('^A'));
    });

    test('separator with padding reduces length', () {
      final sep = ZplSeparator(
        x: 0,
        y: 50,
        type: ZplSeparatorType.box,
        thickness: 1,
        orientation: ZplOrientation.normal,
        paddingLeft: 10,
        paddingRight: 10,
        length: 120,
      );
      final zpl = sep.toZpl(config);
      expect(zpl, contains('^GB'));
      // length 120 - padding (10+10) = 100
      expect(zpl, contains('100,'));
    });

    test('horizontal separator calculateWidth includes full width', () {
      final sep = ZplSeparator(
        x: 0,
        y: 50,
        type: ZplSeparatorType.box,
        thickness: 2,
        orientation: ZplOrientation.normal,
        paddingLeft: 5,
        paddingRight: 5,
        length: 100,
      );
      // (100 - 5 - 5) clamped + 5 + 5 = 90 + 5 + 5 = 100
      expect(sep.calculateWidth(config), 100);
    });

    test('vertical separator calculateWidth returns thickness', () {
      final sep = ZplSeparator(
        x: 100,
        y: 0,
        type: ZplSeparatorType.box,
        thickness: 3,
        orientation: ZplOrientation.rotated90,
        length: 200,
      );
      expect(sep.calculateWidth(config), 3);
    });

    test('separator with custom character uses that character', () {
      final sep = ZplSeparator(
        x: 0,
        y: 50,
        type: ZplSeparatorType.character,
        character: '*',
        orientation: ZplOrientation.normal,
        fontHeight: 12,
        fontWidth: 10,
        length: 50,
      );
      final zpl = sep.toZpl(config);
      expect(zpl, contains('*'));
    });

    test('separator respects maxWidth property when set', () {
      final sep = ZplSeparator(
        x: 0,
        y: 50,
        type: ZplSeparatorType.box,
        thickness: 1,
        orientation: ZplOrientation.normal,
        maxWidth: 200,
      );
      expect(sep.calculateWidth(config), 200);
    });

    test('inverted180 orientation is horizontal', () {
      final sep = ZplSeparator(
        x: 0,
        y: 50,
        type: ZplSeparatorType.box,
        thickness: 2,
        orientation: ZplOrientation.inverted180,
        length: 100,
      );
      final zpl = sep.toZpl(config);
      expect(zpl, contains('^GB100,2,2,B,0^FS'));
    });
  });

  group('box separator thickness', () {
    const config = ZplConfiguration(printWidth: 812, labelLength: 1218);

    test('a horizontal rule 4 dots thick prints solid', () {
      final zpl = ZplSeparator(
        x: 10,
        y: 20,
        thickness: 4,
        length: 300,
      ).toZpl(config);
      expect(zpl, contains('^GB300,4,4,B,0^FS'));
    });

    test('a vertical rule 6 dots thick prints solid', () {
      final zpl = ZplSeparator(
        x: 10,
        y: 20,
        thickness: 6,
        length: 200,
        orientation: ZplOrientation.rotated90,
      ).toZpl(config);
      expect(zpl, contains('^GB6,200,6,B,0^FS'));
    });

    test('a 1-dot rule is unchanged', () {
      final zpl = ZplSeparator(x: 10, y: 20, length: 300).toZpl(config);
      expect(zpl, contains('^GB300,1,1,B,0^FS'));
    });
  });
}
