import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  Gs1ValueError? v(String ai, String value) =>
      Gs1ApplicationIdentifier.lookup(ai)!.validate(value);

  test('check digit of 0950110153000 is 3', () {
    expect(gs1CheckDigit('0950110153000'), 3);
    expect(gs1AppendCheckDigit('0950110153000'), '09501101530003');
    expect(gs1CheckDigit('0000000000000'), 0);
  });

  test('pads GTIN to 14', () {
    expect(gs1PadGtinTo14('9501101530003'), '09501101530003');
    expect(gs1PadGtinTo14('12345670'), '00000012345670');
    expect(gs1PadGtinTo14('123456789012345'), '123456789012345');
  });

  test('registry holds the nine AIs and lookup works', () {
    expect(Gs1ApplicationIdentifier.registry.map((a) => a.code), [
      '01',
      '10',
      '11',
      '13',
      '15',
      '17',
      '21',
      '37',
      '3103',
    ]);
    expect(Gs1ApplicationIdentifier.lookup('99'), isNull);
    final lot = Gs1ApplicationIdentifier.lookup('10')!;
    expect(lot.variableLength, isTrue);
    expect(lot.length, 20);
    expect(lot.name, 'Batch or lot');
  });

  test('valid values pass', () {
    expect(v('01', '09501101530003'), isNull);
    expect(v('17', '261231'), isNull);
    expect(v('10', 'A1-b_2/3'), isNull);
    expect(v('21', 'x' * 20), isNull);
    expect(v('37', '12'), isNull);
    expect(v('3103', '001250'), isNull);
  });

  test('placeholders are always valid', () {
    expect(v('01', '{{gtin}}'), isNull);
    expect(v('17', '{{expiry}}'), isNull);
    expect(v('37', '{{n}}'), isNull);
  });

  test('wrong length', () {
    expect(v('01', '0950110153000'), Gs1ValueError.wrongLength);
    expect(v('17', '2612'), Gs1ValueError.wrongLength);
    expect(v('10', ''), Gs1ValueError.wrongLength);
    expect(v('10', 'x' * 21), Gs1ValueError.wrongLength);
    expect(v('37', '123456789'), Gs1ValueError.wrongLength);
  });

  test('not digits', () {
    expect(v('01', '0950110153000A'), Gs1ValueError.notDigits);
    expect(v('37', '1x'), Gs1ValueError.notDigits);
    expect(v('3103', '00125a'), Gs1ValueError.notDigits);
  });

  test('bad character', () {
    expect(v('10', 'a b'), Gs1ValueError.badCharacter);
    expect(v('21', 'a#b'), Gs1ValueError.badCharacter);
    expect(v('10', 'café'), Gs1ValueError.badCharacter);
  });

  test('bad check digit', () {
    expect(v('01', '09501101530004'), Gs1ValueError.badCheckDigit);
  });

  test('dates: day 00 passes, month 13 and 00 fail, day 32 fails', () {
    expect(v('17', '261200'), isNull);
    expect(v('11', '260131'), isNull);
    expect(v('17', '261300'), Gs1ValueError.badDate);
    expect(v('15', '260031'), Gs1ValueError.badDate);
    expect(v('13', '260132'), Gs1ValueError.badDate);
  });

  test('month length and leap years are checked, day 00 stays allowed', () {
    expect(v('17', '260231'), Gs1ValueError.badDate);
    expect(v('17', '260431'), Gs1ValueError.badDate);
    expect(v('17', '260228'), isNull);
    expect(v('17', '260229'), Gs1ValueError.badDate);
    expect(v('17', '280229'), isNull);
    expect(v('17', '000229'), isNull);
    expect(v('17', '260200'), isNull);
    expect(v('17', '261231'), isNull);
  });

  test('escape characters are rejected, placeholders included', () {
    expect(v('10', 'A~1B'), Gs1ValueError.badCharacter);
    expect(v('10', '{{lot~d029}}'), Gs1ValueError.badCharacter);
    expect(v('10', 'A^FSB'), Gs1ValueError.badCharacter);
    expect(v('10', '{{lot}}'), isNull);
  });
}
