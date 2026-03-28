import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('ZplTemplate', () {
    test('bind() replaces variables correctly through an async call', () async {
      final generator = ZplGenerator(
        config: const ZplConfiguration(printWidth: 406, labelLength: 203),
        commands: [
          ZplText(text: 'Hello {{name}}', x: 10, y: 10),
          ZplText(text: 'Price: \${{price}}', x: 10, y: 50),
          ZplBarcode(
              data: '{{barcode}}',
              x: 10,
              y: 90,
              height: 50,
              type: ZplBarcodeType.code128),
        ],
      );

      final template = ZplTemplate(generator);

      final result1 = await template
          .bind({'name': 'John Doe', 'price': '19.99', 'barcode': '123456789'});

      expect(result1, contains('^FDHello John Doe^FS'));
      expect(result1, contains('^FDPrice: \$19.99^FS'));
      expect(result1, contains('^FD123456789^FS'));

      // Validate that it can bind again safely
      final result2 = await template
          .bind({'name': 'Jane Doe', 'price': '42.00', 'barcode': '987654321'});

      expect(result2, contains('^FDHello Jane Doe^FS'));
      expect(result2, contains('^FDPrice: \$42.00^FS'));
      expect(result2, contains('^FD987654321^FS'));
    });

    test('bindSync() throws StateError if not initialized', () {
      final generator = ZplGenerator(
        config: const ZplConfiguration(printWidth: 400, labelLength: 400),
        commands: [ZplText(text: 'Test')],
      );
      final template = ZplTemplate(generator);

      expect(
        () => template.bindSync({'any': 'data'}),
        throwsStateError,
      );
    });

    test('bindSync() resolves correctly after init()', () async {
      final generator = ZplGenerator(
        config: const ZplConfiguration(printWidth: 400, labelLength: 400),
        commands: [
          ZplText(text: 'SKU: {{sku}}'),
          ZplBox(x: 20, y: 20, width: 100, height: 100),
        ],
      );
      final template = ZplTemplate(generator);

      await template.init();

      final result = template.bindSync({'sku': 'ABC-123'});

      expect(result, contains('^FDSKU: ABC-123^FS'));
      expect(
          result,
          contains(
              '^GB100,100,1,B,0^FS')); // Ensures normal geometry wasn't impacted
    });
  });
}
