import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('ZplGraphicSymbol', () {
    test('renders correctly with default orientation', () {
      final symbol = ZplGraphicSymbol(
        x: 10,
        y: 20,
        symbol: ZplGraphicSymbolType.registeredTrademark,
        width: 50,
        height: 50,
      );

      final result = symbol.toZpl(const ZplConfiguration());
      expect(result, equals('^FO10,20\n^GSN,50,50\n^FDA^FS\n'));
    });

    test('renders correctly with specific parameters', () {
      final symbol = ZplGraphicSymbol(
        x: 100,
        y: 200,
        symbol: ZplGraphicSymbolType.copyright,
        width: 30,
        height: 60,
        orientation: 'R',
      );

      final result = symbol.toZpl(const ZplConfiguration());
      expect(result, equals('^FO100,200\n^GSR,60,30\n^FDB^FS\n'));
    });

    test('calculates correct width', () {
      final symbol = ZplGraphicSymbol(
        symbol: ZplGraphicSymbolType.registeredTrademark,
        width: 75,
        height: 50,
      );

      expect(symbol.calculateWidth(const ZplConfiguration()), equals(75));
    });

    test('throws assertion error for invalid orientation', () {
      expect(
        () => ZplGraphicSymbol(
          symbol: ZplGraphicSymbolType.registeredTrademark,
          width: 50,
          height: 50,
          orientation: 'X',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
