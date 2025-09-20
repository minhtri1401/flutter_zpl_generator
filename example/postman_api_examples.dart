// Postman API Examples for Labelary Service
// This file generates ZPL and shows exactly how to call the Labelary API using Postman

import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  print('=== LABELARY API - POSTMAN EXAMPLES ===\n');
  print('Base URL: https://api.labelary.com/v1\n');

  // Example 1: Basic Hello World Label
  _printPostmanExample(
    title: '1. BASIC HELLO WORLD LABEL',
    commands: [
      const ZplConfiguration(
        printWidth: 406,
        labelLength: 609,
        printDensity: ZplPrintDensity.d8,
      ),
      const ZplText(x: 50, y: 50, text: 'Hello World'),
    ],
    density: '8dpmm',
    width: '2.0',
    height: '3.0',
    index: '0',
    outputFormat: 'PNG',
    acceptHeader: 'image/png',
  );

  // Example 2: Label with Barcode (PDF)
  _printPostmanExample(
    title: '2. LABEL WITH BARCODE (PDF OUTPUT)',
    commands: [
      const ZplConfiguration(
        printWidth: 812,
        labelLength: 1218,
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
    ],
    density: '8dpmm',
    width: '4.0',
    height: '6.0',
    index: '0',
    outputFormat: 'PDF',
    acceptHeader: 'application/pdf',
  );

  // Example 3: High Density Label
  _printPostmanExample(
    title: '3. HIGH DENSITY LABEL (24dpmm)',
    commands: [
      const ZplConfiguration(
        printWidth: 1200,
        labelLength: 900,
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
    ],
    density: '24dpmm',
    width: '2.0',
    height: '1.5',
    index: '0',
    outputFormat: 'PNG',
    acceptHeader: 'image/png',
  );

  // Example 4: Multiple Labels (Get 2nd label)
  _printMultiLabelExample();

  // Example 5: QR Code Label
  _printPostmanExample(
    title: '5. QR CODE LABEL',
    commands: [
      const ZplConfiguration(
        printWidth: 406,
        labelLength: 406,
        printDensity: ZplPrintDensity.d8,
      ),
      const ZplText(x: 50, y: 30, text: 'Scan QR Code:'),
      const ZplBarcode(
        x: 100,
        y: 80,
        data: 'https://example.com/product/12345',
        type: ZplBarcodeType.qrCode,
        height: 100,
      ),
      const ZplText(x: 30, y: 200, text: 'Product ID: 12345'),
    ],
    density: '8dpmm',
    width: '2.0',
    height: '2.0',
    index: '0',
    outputFormat: 'PNG',
    acceptHeader: 'image/png',
  );

  // Example 6: JSON Output for Data Extraction
  _printPostmanExample(
    title: '6. JSON OUTPUT (DATA EXTRACTION)',
    commands: [
      const ZplConfiguration(
        printWidth: 812,
        labelLength: 609,
        printDensity: ZplPrintDensity.d8,
      ),
      const ZplText(x: 50, y: 50, text: 'Product: ABC123'),
      const ZplText(x: 50, y: 100, text: 'Price: \$19.99'),
      const ZplBarcode(
        x: 50,
        y: 150,
        data: '123456789',
        type: ZplBarcodeType.code128,
        height: 80,
        moduleWidth: 2,
      ),
    ],
    density: '8dpmm',
    width: '4.0',
    height: '3.0',
    index: '0',
    outputFormat: 'JSON',
    acceptHeader: 'application/json',
  );

  // Conversion APIs
  _printConversionAPIs();

  // Error Testing
  _printErrorExamples();

  print('\n=== QUICK COPY-PASTE FOR POSTMAN ===\n');
  print('Base URL for all requests: https://api.labelary.com/v1\n');
  print('Most common endpoint: POST {{baseUrl}}/8dpmm/labels/4.0x6.0/0/\n');
  print('Headers to set:');
  print('  Content-Type: application/x-www-form-urlencoded');
  print('  Accept: image/png (or application/pdf, application/json)\n');
  print('Body type: raw text (put the ZPL in the request body)\n');
}

void _printPostmanExample({
  required String title,
  required List<ZplCommand> commands,
  required String density,
  required String width,
  required String height,
  required String index,
  required String outputFormat,
  required String acceptHeader,
}) {
  final generator = ZplGenerator(commands);
  final zpl = generator.build();

  print(title);
  print('=' * title.length);
  print('HTTP Method: POST');
  print(
    'URL: https://api.labelary.com/v1/printers/$density/labels/${width}x$height/$index/',
  );
  print('');
  print('Headers:');
  print('  Content-Type: application/x-www-form-urlencoded');
  print('  Accept: $acceptHeader');
  print('');
  print('Body (raw text):');
  print(zpl);
  print('Expected Output: $outputFormat file');
  print('');
  print('CURL Example:');
  print(
    'curl -X POST "https://api.labelary.com/v1/printers/$density/labels/${width}x$height/$index/" \\',
  );
  print('  -H "Content-Type: application/x-www-form-urlencoded" \\');
  print('  -H "Accept: $acceptHeader" \\');
  print('  --data-raw \'$zpl\' \\');
  print('  --output "label_output.$_getFileExtension(outputFormat)"');
  print('\n${'-' * 80}\n');
}

void _printMultiLabelExample() {
  print('4. MULTIPLE LABELS (GET 2ND LABEL)');
  print('=' * 35);

  final label1Commands = [
    const ZplConfiguration(
      printWidth: 609,
      labelLength: 406,
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

  final multipleZpl =
      generator1.build() + generator2.build() + generator3.build();

  print('HTTP Method: POST');
  print(
    'URL: https://api.labelary.com/v1/printers/8dpmm/labels/3.0x2.0/1/  ← Note index=1 for 2nd label',
  );
  print('');
  print('Headers:');
  print('  Content-Type: application/x-www-form-urlencoded');
  print('  Accept: image/png');
  print('');
  print('Body (raw text):');
  print(multipleZpl);
  print('Expected Output: PNG file (only the 2nd label)');
  print('');
  print('Note: Change index to 0, 1, or 2 to get different labels');
  print('  Index 0: Label 1');
  print('  Index 1: Label 2');
  print('  Index 2: Label 3');
  print('\n${'-' * 80}\n');
}

void _printConversionAPIs() {
  print('IMAGE TO ZPL CONVERSION API');
  print('=' * 30);
  print('HTTP Method: POST');
  print('URL: https://api.labelary.com/v1/printers/graphics');
  print('');
  print('Headers:');
  print('  Content-Type: multipart/form-data');
  print('  Accept: application/zpl');
  print('');
  print('Body: form-data');
  print('  Key: file');
  print('  Value: [Select image file - PNG, JPG, etc.]');
  print('');
  print('Expected Output: ZPL graphic commands (~DG)');
  print('\n${'-' * 40}\n');

  print('FONT TO ZPL CONVERSION API');
  print('=' * 27);
  print('HTTP Method: POST');
  print('URL: https://api.labelary.com/v1/printers/fonts');
  print('');
  print('Headers:');
  print('  Content-Type: multipart/form-data');
  print('  Accept: application/zpl');
  print('');
  print('Body: form-data');
  print('  Key: file, Value: [Select TTF font file]');
  print('  Key: name, Value: Z (optional - single letter font name)');
  print('  Key: path, Value: E:MYFONT.TTF (optional - printer path)');
  print(
    '  Key: chars, Value: ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 (optional - subset)',
  );
  print('');
  print('Expected Output: ZPL font commands (~DU, ^CW)');
  print('\n${'-' * 40}\n');
}

void _printErrorExamples() {
  print('ERROR TESTING EXAMPLES');
  print('=' * 22);
  print('');
  print('1. Invalid ZPL (should return 400):');
  print('URL: https://api.labelary.com/v1/printers/8dpmm/labels/4.0x6.0/0/');
  print('Body: ^XA^InvalidCommand^XZ');
  print('');
  print('2. Dimension too large (should return 400):');
  print(
    'URL: https://api.labelary.com/v1/printers/8dpmm/labels/20.0x20.0/0/  ← Exceeds 15" limit',
  );
  print('Body: ^XA^FO50,50^A0N,50,50^FDTest^FS^XZ');
  print('');
  print('3. Invalid density (should return 404):');
  print(
    'URL: https://api.labelary.com/v1/printers/99dpmm/labels/4.0x6.0/0/  ← Invalid density',
  );
  print('Body: ^XA^FO50,50^A0N,50,50^FDTest^FS^XZ');
  print('\n${'-' * 40}\n');
}

String _getFileExtension(String outputFormat) {
  switch (outputFormat.toLowerCase()) {
    case 'png':
      return 'png';
    case 'pdf':
      return 'pdf';
    case 'json':
      return 'json';
    default:
      return 'bin';
  }
}
