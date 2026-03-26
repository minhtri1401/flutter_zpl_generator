import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('ZplText Serialization Tests', () {
    test('standard serialization overrides FD with SN data', () {
      final text = ZplText(
        x: 50,
        y: 50,
        text: '001',
        serialization: const ZplSerialConfig(
          increment: 1,
          leadingZeros: true,
        ),
      );

      final result = text.toZpl(const ZplConfiguration());
      expect(result, contains('^SN001,1,Y^FS'));
      expect(result, isNot(contains('^FD')));
    });

    test('serialization with alphanumeric prefix', () {
      final text = ZplText(
        x: 50,
        y: 50,
        text: 'LOT-100',
        serialization: const ZplSerialConfig(
          increment: 5,
          leadingZeros: false,
        ),
      );

      final result = text.toZpl(const ZplConfiguration());
      expect(result, contains('^SNLOT-100,5,N^FS'));
    });

    test('serialization decrementing sequence', () {
      final text = ZplText(
        x: 50,
        y: 50,
        text: '999',
        serialization: const ZplSerialConfig(
          increment: -1,
          leadingZeros: true,
        ),
      );

      final result = text.toZpl(const ZplConfiguration());
      expect(result, contains('^SN999,-1,Y^FS'));
    });
    
    test('serialization retains formatting properties', () {
      final text = ZplText(
        x: 10,
        y: 20,
        text: '1',
        font: ZplFont.d,
        reversePrint: true,
        serialization: const ZplSerialConfig(increment: 10, leadingZeros: true),
      );

      final result = text.toZpl(const ZplConfiguration());
      expect(result, contains('^FO10,20'));
      expect(result, contains('^AD'));
      expect(result, contains('^FR'));
      expect(result, contains('^SN1,10,Y^FS'));
    });
  });
}
