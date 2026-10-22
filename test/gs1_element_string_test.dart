import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  const full = '(01)09501101530003(17)261231(10)A1';

  test('parses and formats back unchanged', () {
    final els = Gs1ElementString.parse(full);
    expect(els.map((e) => e.ai.code), ['01', '17', '10']);
    expect(els.map((e) => e.value), ['09501101530003', '261231', 'A1']);
    expect(Gs1ElementString.format(els), full);
    expect(els.first.toString(), '(01)09501101530003');
  });

  test('parses placeholders', () {
    final els = Gs1ElementString.parse('(10){{lot}}(21){{sn}}');
    expect(els.map((e) => e.value), ['{{lot}}', '{{sn}}']);
  });

  test('fails on unknown AI and malformed input', () {
    for (final bad in [
      '(99)x',
      '',
      'abc',
      '(01',
      '(01(17)1',
      '(10)',
      '(10)(17)261231',
      '(10)a)b',
    ]) {
      expect(
        () => Gs1ElementString.parse(bad),
        throwsFormatException,
        reason: bad,
      );
      expect(Gs1ElementString.tryParse(bad), isNull);
    }
    expect(Gs1ElementString.tryParse(full), isNotNull);
  });

  test('element equality', () {
    final a = Gs1ElementString.parse('(10)A');
    final b = Gs1ElementString.parse('(10)A');
    expect(a.first, b.first);
    expect(a.first.hashCode, b.first.hashCode);
    expect(a.first == Gs1ElementString.parse('(10)B').first, isFalse);
    expect(a.first == Object(), isFalse);
  });

  test('FNC1 form puts a separator only after variable-length AIs', () {
    final els = Gs1ElementString.parse(
      '(01)09501101530003(17)261231(10)A1(21)S9',
    );
    expect(
      Gs1ElementString.toFnc1(els),
      '@1010950110153000317261231'
      '10A1@d02921S9',
    );
    expect(
      Gs1ElementString.parenthesisedToFnc1(full),
      '@101095011015300031726123110A1',
    );
    expect(
      Gs1ElementString.toFnc1(els, escape: '_'),
      '_1010950110153000317261231'
      '10A1_d02921S9',
    );
  });

  test('the default escape is @ and ~ is still available', () {
    expect(kGs1DataMatrixEscape, '@');
    final els = Gs1ElementString.parse('(10)A(21)B');
    expect(Gs1ElementString.toFnc1(els), '@110A@d02921B');
    expect(Gs1ElementString.toFnc1(els, escape: '~'), '~110A~d02921B');
    expect(Gs1ElementString.fromFnc1('~110A~d02921B', escape: '~'), els);
    expect(Gs1ElementString.tryFromFnc1('~110A~d02921B'), isNull);
  });

  test('placeholders convert without lengths', () {
    expect(
      Gs1ElementString.parenthesisedToFnc1('(10){{lot}}(17){{e}}'),
      '@110{{lot}}@d0291'
      '7{{e}}',
    );
  });

  test('back-conversion returns the same pairs', () {
    for (final text in [
      full,
      '(01)09501101530003(17)261231(10)A1(21)S9',
      '(10)LOT(21)SER',
      '(37)12(3103)001250',
      '(10){{lot}}(17){{e}}',
    ]) {
      final els = Gs1ElementString.parse(text);
      expect(
        Gs1ElementString.fromFnc1(Gs1ElementString.toFnc1(els)),
        els,
        reason: text,
      );
    }
    final alt = Gs1ElementString.parse('(10)A(21)B');
    expect(
      Gs1ElementString.fromFnc1(
        Gs1ElementString.toFnc1(alt, escape: '_'),
        escape: '_',
      ),
      alt,
    );
  });

  test('back-conversion fails on bad data', () {
    for (final bad in [
      '0109501101530003',
      '@1',
      '@199abc',
      '@101095011015',
      '@110{{open',
      '@110@d029',
      '@110A@d029',
      '@1',
    ]) {
      expect(
        () => Gs1ElementString.fromFnc1(bad),
        throwsFormatException,
        reason: bad,
      );
      expect(Gs1ElementString.tryFromFnc1(bad), isNull);
    }
    expect(Gs1ElementString.tryFromFnc1('@110A'), isNotNull);
  });

  test('toFnc1 rejects a value that contains the escape character', () {
    final lot = Gs1ApplicationIdentifier.lookup('10')!;
    expect(
      () => Gs1ElementString.toFnc1([Gs1Element(lot, 'A@d029B')]),
      throwsFormatException,
    );
    expect(
      () => Gs1ElementString.toFnc1([Gs1Element(lot, 'A_1')], escape: '_'),
      throwsFormatException,
    );
  });

  test('a repeated AI is a FormatException', () {
    expect(() => Gs1ElementString.parse('(10)A(10)B'), throwsFormatException);
    expect(Gs1ElementString.tryParse('(10)A(10)B'), isNull);
    expect(
      () => Gs1ElementString.fromFnc1('@110A@d02910B'),
      throwsFormatException,
    );
    expect(Gs1ElementString.tryFromFnc1('@110A@d02910B'), isNull);
  });

  group('modeDFieldData', () {
    test('separates a variable-length value from the next AI', () {
      expect(
        Gs1ElementString.modeDFieldData('(10){{lot}}(21){{sn}}'),
        '(10){{lot}}>8(21){{sn}}',
      );
      expect(
        Gs1ElementString.modeDFieldData('(10)ABC(21)123'),
        '(10)ABC>8(21)123',
      );
      expect(
        Gs1ElementString.modeDFieldData('(10)ABC(17)261231'),
        '(10)ABC>8(17)261231',
      );
    });

    test('leaves a trailing variable-length value alone', () {
      expect(Gs1ElementString.modeDFieldData(full), full);
      expect(
        Gs1ElementString.modeDFieldData('(01)09501101530003'),
        '(01)09501101530003',
      );
    });

    test('leaves plain digits, existing separators and bad data alone', () {
      expect(
        Gs1ElementString.modeDFieldData('0109501101530003'),
        '0109501101530003',
      );
      expect(
        Gs1ElementString.modeDFieldData('(10)ABC>8(21)123'),
        '(10)ABC>8(21)123',
      );
      expect(Gs1ElementString.modeDFieldData('(99)x(10)y'), '(99)x(10)y');
      expect(Gs1ElementString.modeDFieldData(''), '');
    });
  });
}
