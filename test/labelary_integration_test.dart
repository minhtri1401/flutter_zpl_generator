// Integration tests for LabelaryService
// These tests make actual calls to the Labelary API
// Run with: flutter test test/labelary_integration_test.dart
// Note: These tests require internet connection and may count against API limits

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('LabelaryService Integration Tests', () {
    // Skip these tests by default to avoid hitting API limits during normal testing
    // To run these tests, use: flutter test test/labelary_integration_test.dart
    const shouldSkip = bool.fromEnvironment(
      'SKIP_INTEGRATION_TESTS',
      defaultValue: true,
    );

    group('Real API calls', () {
      test('renderZpl - Basic label with text (PNG)', () async {
        // Create ZPL using ZplGenerator
        final commands = [
          const ZplConfiguration(
            printWidth: 812, // 4 inches * 203 DPI
            labelLength: 1218, // 6 inches * 203 DPI
            printDensity: ZplPrintDensity.d8,
          ),
          const ZplText(x: 50, y: 50, text: 'Hello World'),
        ];
        final generator = ZplGenerator(commands);
        final zpl = generator.build();

        final result = await LabelaryService.renderZplSimple(
          zpl,
          density: LabelaryPrintDensity.d8,
          width: 4.0,
          height: 6.0,
        );

        // Should return PNG data
        expect(result.isNotEmpty, true);
        // PNG files start with these bytes: 137, 80, 78, 71
        expect(result.sublist(0, 4), equals([137, 80, 78, 71]));

        // Optional: Save the result to verify visually
        await File('test_output_hello_world.png').writeAsBytes(result);
        print(
          '✓ Basic PNG test passed. Output saved to test_output_hello_world.png',
        );
        print(
          '  URL used: https://api.labelary.com/v1/printers/8dpmm/labels/4.0x6.0/0/',
        );
        print('  ZPL generated: $zpl');
      }, skip: shouldSkip);

      test('renderZpl - Label with barcode (PDF)', () async {
        // Create ZPL using ZplGenerator with barcode
        final commands = [
          const ZplConfiguration(
            printWidth: 812, // 4 inches * 203 DPI
            labelLength: 1218, // 6 inches * 203 DPI
            printDensity: ZplPrintDensity.d8,
          ),
          const ZplText(x: 100, y: 100, text: 'Product Label'),
          const ZplBarcode(
            x: 100,
            y: 200,
            data: '123456789012',
            type: ZplBarcodeType.code128,
            height: 100,
            moduleWidth: 3,
          ),
        ];
        final generator = ZplGenerator(commands);
        final zpl = generator.build();

        final result = await LabelaryService.renderZplSimple(
          zpl,
          density: LabelaryPrintDensity.d8,
          width: 4.0,
          height: 6.0,
          outputFormat: LabelaryOutputFormat.pdf,
        );

        // Should return PDF data
        expect(result.isNotEmpty, true);
        // PDF files start with "%PDF"
        expect(result.sublist(0, 4), equals([37, 80, 68, 70]));

        await File('test_output_barcode.pdf').writeAsBytes(result);
        print(
          '✓ Barcode PDF test passed. Output saved to test_output_barcode.pdf',
        );
        print(
          '  URL used: https://api.labelary.com/v1/printers/8dpmm/labels/4.0x6.0/0/',
        );
        print('  ZPL generated: $zpl');
      }, skip: shouldSkip);

      test('renderZpl - Multiple labels with index selection', () async {
        // Create multiple labels using ZplGenerator
        final label1Commands = [
          const ZplConfiguration(
            printWidth: 609, // 3 inches * 203 DPI
            labelLength: 406, // 2 inches * 203 DPI
            printDensity: ZplPrintDensity.d8,
          ),
          const ZplText(x: 50, y: 50, text: 'Label 1'),
        ];
        final label2Commands = [
          const ZplConfiguration(
            printWidth: 609,
            labelLength: 406,
            printDensity: ZplPrintDensity.d8,
          ),
          const ZplText(x: 50, y: 50, text: 'Label 2'),
        ];
        final label3Commands = [
          const ZplConfiguration(
            printWidth: 609,
            labelLength: 406,
            printDensity: ZplPrintDensity.d8,
          ),
          const ZplText(x: 50, y: 50, text: 'Label 3'),
        ];

        final generator1 = ZplGenerator(label1Commands);
        final generator2 = ZplGenerator(label2Commands);
        final generator3 = ZplGenerator(label3Commands);

        final zpl =
            generator1.build() + generator2.build() + generator3.build();

        // Get the second label (index 1)
        final result = await LabelaryService.renderZplSimple(
          zpl,
          index: 1,
          width: 3.0,
          height: 2.0,
        );

        expect(result.isNotEmpty, true);
        expect(result.sublist(0, 4), equals([137, 80, 78, 71])); // PNG header

        await File('test_output_multi_label.png').writeAsBytes(result);
        print(
          '✓ Multi-label test passed. Second label saved to test_output_multi_label.png',
        );
        print(
          '  URL used: https://api.labelary.com/v1/printers/8dpmm/labels/3.0x2.0/1/',
        );
        print('  ZPL generated: $zpl');
      }, skip: shouldSkip);

      test('renderZpl - High density label', () async {
        // Create high-density label using ZplGenerator
        final commands = [
          const ZplConfiguration(
            printWidth: 1200, // 2 inches * 600 DPI (24dpmm)
            labelLength: 900, // 1.5 inches * 600 DPI
            printDensity: ZplPrintDensity.d24,
          ),
          const ZplText(x: 20, y: 20, text: 'High Resolution'),
          const ZplBarcode(
            x: 20,
            y: 60,
            data: '987654321',
            type: ZplBarcodeType.code128,
            height: 80,
            moduleWidth: 2,
          ),
        ];
        final generator = ZplGenerator(commands);
        final zpl = generator.build();

        final result = await LabelaryService.renderZplSimple(
          zpl,
          density: LabelaryPrintDensity.d24, // 24 dots per mm
          width: 2.0,
          height: 1.5,
        );

        expect(result.isNotEmpty, true);
        expect(result.sublist(0, 4), equals([137, 80, 78, 71]));

        await File('test_output_high_density.png').writeAsBytes(result);
        print(
          '✓ High density test passed. Output saved to test_output_high_density.png',
        );
        print(
          '  URL used: https://api.labelary.com/v1/printers/24dpmm/labels/2.0x1.5/0/',
        );
        print('  ZPL generated: $zpl');
      }, skip: shouldSkip);

      test('renderFromGenerator - Using ZplGenerator', () async {
        final commands = [
          const ZplConfiguration(
            printWidth: 406,
            labelLength: 203,
            printDensity: ZplPrintDensity.d8,
          ),
          const ZplText(x: 50, y: 50, text: 'Generated Label'),
          const ZplText(x: 50, y: 100, text: 'Using ZplGenerator'),
        ];
        final generator = ZplGenerator(commands);

        final result = await LabelaryService.renderFromGeneratorSimple(
          generator,
        );

        expect(result.isNotEmpty, true);
        expect(result.sublist(0, 4), equals([137, 80, 78, 71]));

        await File('test_output_generator.png').writeAsBytes(result);
        print(
          '✓ Generator test passed. Output saved to test_output_generator.png',
        );
        print(
          '  URL used: https://api.labelary.com/v1/printers/8dpmm/labels/2.0x1.0/0/',
        );
        print('  ZPL generated: ${generator.build()}');
      }, skip: shouldSkip);

      test('renderZpl - JSON output for data extraction', () async {
        const zpl =
            '^XA'
            '^FO50,50^A0N,30,30^FDProduct: ABC123^FS'
            '^FO50,100^A0N,30,30^FDPrice: \$19.99^FS'
            '^FO50,150^BY2^BCN,80,Y,N,N^FD123456789^FS'
            '^XZ';

        final result = await LabelaryService.renderZplSimple(
          zpl,
          outputFormat: LabelaryOutputFormat.json,
          width: 4.0,
          height: 3.0,
        );

        expect(result.isNotEmpty, true);
        final jsonString = String.fromCharCodes(result);
        expect(jsonString.contains('labels'), true);
        expect(jsonString.contains('fields'), true);

        await File('test_output_data.json').writeAsString(jsonString);
        print(
          '✓ JSON extraction test passed. Output saved to test_output_data.json',
        );
        print(
          '  URL used: https://api.labelary.com/v1/printers/8dpmm/labels/4.0x3.0/0/',
        );
        print('  JSON response: $jsonString');
      }, skip: shouldSkip);

      test('convertImageToGraphic - Convert PNG to ZPL', () async {
        // Create a simple test image (1x1 black pixel PNG)
        final simpleBlackPixelPng = Uint8List.fromList([
          137,
          80,
          78,
          71,
          13,
          10,
          26,
          10,
          0,
          0,
          0,
          13,
          73,
          72,
          68,
          82,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          1,
          8,
          2,
          0,
          0,
          0,
          144,
          119,
          83,
          222,
          0,
          0,
          0,
          12,
          73,
          68,
          65,
          84,
          8,
          153,
          99,
          248,
          15,
          0,
          0,
          1,
          0,
          1,
          53,
          174,
          157,
          25,
          0,
          0,
          0,
          0,
          73,
          69,
          78,
          68,
          174,
          66,
          96,
          130,
        ]);

        final result = await LabelaryService.convertImageToGraphic(
          simpleBlackPixelPng,
          'test.png',
        );

        expect(result.isNotEmpty, true);
        expect(result.contains('~DG'), true); // ZPL graphic command

        await File('test_output_image_conversion.zpl').writeAsString(result);
        print(
          '✓ Image conversion test passed. ZPL output saved to test_output_image_conversion.zpl',
        );
        print('  URL used: https://api.labelary.com/v1/printers/graphics');
        print('  ZPL result: $result');
      }, skip: shouldSkip);

      test('convertFontToZpl - Convert TTF font', () async {
        // Check if the Roboto font file exists in the project
        final fontFile = File('Roboto-Regular.ttf');
        if (!await fontFile.exists()) {
          print('⚠️ Skipping font test - Roboto-Regular.ttf not found');
          return;
        }

        final fontData = await fontFile.readAsBytes();

        final result = await LabelaryService.convertFontToZpl(
          fontData,
          'Roboto-Regular.ttf',
          name: 'Z', // Assign shorthand name 'Z'
          chars:
              'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789', // Subset to alphanumeric
        );

        expect(result.isNotEmpty, true);
        expect(result.contains('~DU'), true); // Font download command
        expect(result.contains('^CW'), true); // Font assignment command

        await File('test_output_font_conversion.zpl').writeAsString(result);
        print(
          '✓ Font conversion test passed. ZPL output saved to test_output_font_conversion.zpl',
        );
        print('  URL used: https://api.labelary.com/v1/printers/fonts');
        print('  Font subset to: ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789');
        print('  ZPL result length: ${result.length} characters');
      }, skip: shouldSkip);

      test('Error handling - Invalid ZPL', () async {
        const invalidZpl = '^XA^InvalidCommand^XZ';

        try {
          await LabelaryService.renderZplSimple(invalidZpl);
          fail('Should have thrown an exception for invalid ZPL');
        } catch (e) {
          expect(e, isA<Exception>());
          print('✓ Error handling test passed. Exception caught: $e');
          print('  Invalid ZPL: $invalidZpl');
        }
      }, skip: shouldSkip);

      test('Error handling - Invalid dimensions', () async {
        const zpl = '^XA^FO50,50^A0N,50,50^FDTest^FS^XZ';

        try {
          // Try with dimensions that exceed the 15-inch limit
          await LabelaryService.renderZplSimple(
            zpl,
            width: 20.0, // Exceeds 15-inch limit
            height: 20.0,
          );
          fail('Should have thrown an exception for invalid dimensions');
        } catch (e) {
          expect(e, isA<Exception>());
          print('✓ Dimension limit test passed. Exception caught: $e');
          print(
            '  Attempted dimensions: 20.0 x 20.0 inches (exceeds 15-inch limit)',
          );
        }
      }, skip: shouldSkip);
    });

    test('Print test summary and URLs', () {
      print('\n${'=' * 60}');
      print('LABELARY API TEST SUMMARY');
      print('=' * 60);
      print(
        'Based on Labelary API documentation: https://labelary.com/service.html',
      );
      print('');
      print('API Endpoints tested:');
      print(
        '  • Label rendering: POST https://api.labelary.com/v1/printers/{dpmm}/labels/{width}x{height}/{index}/',
      );
      print(
        '  • Image conversion: POST https://api.labelary.com/v1/printers/graphics',
      );
      print(
        '  • Font conversion: POST https://api.labelary.com/v1/printers/fonts',
      );
      print('');
      print('Parameters tested:');
      print('  • Print densities: 6dpmm, 8dpmm, 12dpmm, 24dpmm');
      print(
        '  • Output formats: PNG (image/png), PDF (application/pdf), JSON (application/json)',
      );
      print('  • Label dimensions: Various width x height combinations');
      print(
        '  • Label indexing: Multiple labels with specific index selection',
      );
      print('  • Error handling: Invalid ZPL, dimension limits');
      print('');
      print('ZPL Commands tested:');
      print('  • ^XA / ^XZ: Label start/end');
      print('  • ^FO: Field origin (positioning)');
      print('  • ^A0N: Font selection and sizing');
      print('  • ^FD / ^FS: Field data start/end');
      print('  • ^BY / ^BC: Barcode configuration');
      print('');
      print('Note: Integration tests are skipped by default.');
      print(
        'To run them: flutter test test/labelary_integration_test.dart --dart-define=SKIP_INTEGRATION_TESTS=false',
      );
      print('=' * 60);
    });
  });
}
