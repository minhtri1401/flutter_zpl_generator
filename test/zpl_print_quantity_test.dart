import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('Print Quantity Tests (^PQ)', () {
    final config = const ZplConfiguration(
      printWidth: 406,
      labelLength: 203,
      printDensity: ZplPrintDensity.d8,
    );

    test('Basic quantity is formatted correctly', () {
      final cmd = ZplPrintQuantity(quantity: 50);
      expect(cmd.toZpl(config), '^PQ50');
    });

    test('Includes pause interval', () {
      final cmd = ZplPrintQuantity(quantity: 50, pauseInterval: 10);
      expect(cmd.toZpl(config), '^PQ50,10');
    });

    test('Includes replicates with default pause 0', () {
      final cmd = ZplPrintQuantity(quantity: 50, replicatesPerSerial: 5);
      expect(cmd.toZpl(config), '^PQ50,0,5');
    });

    test('Overrides pause correctly with early params forced to 0', () {
      final cmd = ZplPrintQuantity(quantity: 50, overridePause: true);
      expect(cmd.toZpl(config), '^PQ50,0,0,Y');
    });

    test('Format with pause and override', () {
      final cmd = ZplPrintQuantity(
        quantity: 50,
        pauseInterval: 10,
        overridePause: true,
      );
      expect(cmd.toZpl(config), '^PQ50,10,0,Y');
    });

    test('Sets all parameters simultaneously', () {
      final cmd = ZplPrintQuantity(
        quantity: 100,
        pauseInterval: 15,
        replicatesPerSerial: 2,
        overridePause: false, // Default false is rendered as "N" if full length
        cutOnRfidVoid: true,
      );
      expect(cmd.toZpl(config), '^PQ100,15,2,N,Y');
    });

    test('Assert fails on invalid quantity', () {
      expect(
        () => ZplPrintQuantity(quantity: 0),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => ZplPrintQuantity(quantity: 100000000),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
