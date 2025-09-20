// ZPL Generation Demo
// This file demonstrates how to generate ZPL using ZplGenerator and ZplConfiguration
// instead of writing raw ZPL strings.

import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  print('=== ZPL Generation Examples ===\n');

  // Example 1: Basic "Hello World" label
  print('1. Basic Text Label:');
  final basicCommands = [
    const ZplConfiguration(
      printWidth: 406,
      labelLength: 609,
      printDensity: ZplPrintDensity.d8,
    ),
    const ZplText(x: 50, y: 50, text: 'Hello World'),
  ];
  final basicGenerator = ZplGenerator(basicCommands);
  final basicZpl = basicGenerator.build();
  print('Generated ZPL:');
  print(basicZpl);
  print('URL: https://api.labelary.com/v1/printers/8dpmm/labels/2.0x3.0/0/');
  print('');

  // Example 2: Label with barcode
  print('2. Label with Barcode:');
  final barcodeCommands = [
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
  final barcodeGenerator = ZplGenerator(barcodeCommands);
  final barcodeZpl = barcodeGenerator.build();
  print('Generated ZPL:');
  print(barcodeZpl);
  print('URL: https://api.labelary.com/v1/printers/8dpmm/labels/4.0x6.0/0/');
  print('');

  // Example 3: High-density label
  print('3. High-Density Label:');
  final highDensityCommands = [
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
  final highDensityGenerator = ZplGenerator(highDensityCommands);
  final highDensityZpl = highDensityGenerator.build();
  print('Generated ZPL:');
  print(highDensityZpl);
  print('URL: https://api.labelary.com/v1/printers/24dpmm/labels/2.0x1.5/0/');
  print('');

  // Example 4: Complex label with multiple elements
  print('4. Complex Label:');
  final complexCommands = [
    const ZplConfiguration(
      printWidth: 812,
      labelLength: 1218,
      printDensity: ZplPrintDensity.d12,
      darkness: 15,
      printSpeed: 4,
    ),
    const ZplText(x: 50, y: 50, text: 'SHIPPING LABEL'),
    const ZplText(x: 50, y: 100, text: 'FROM: Company ABC'),
    const ZplText(x: 50, y: 130, text: '123 Business St.'),
    const ZplText(x: 50, y: 160, text: 'City, ST 12345'),
    const ZplText(x: 50, y: 220, text: 'TO: Customer XYZ'),
    const ZplText(x: 50, y: 250, text: '456 Home Ave.'),
    const ZplText(x: 50, y: 280, text: 'Town, ST 67890'),
    const ZplBarcode(
      x: 50,
      y: 350,
      data: 'TRK123456789',
      type: ZplBarcodeType.code128,
      height: 120,
      moduleWidth: 3,
    ),
    const ZplText(x: 50, y: 500, text: 'Tracking: TRK123456789'),
  ];
  final complexGenerator = ZplGenerator(complexCommands);
  final complexZpl = complexGenerator.build();
  print('Generated ZPL:');
  print(complexZpl);
  print('URL: https://api.labelary.com/v1/printers/12dpmm/labels/4.0x6.0/0/');
  print('');

  // Example 5: Multiple labels in one ZPL script
  print('5. Multiple Labels:');
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
  print('Generated ZPL (3 labels):');
  print(multipleZpl);
  print(
    'URL (for label index 0): https://api.labelary.com/v1/printers/8dpmm/labels/3.0x2.0/0/',
  );
  print(
    'URL (for label index 1): https://api.labelary.com/v1/printers/8dpmm/labels/3.0x2.0/1/',
  );
  print(
    'URL (for label index 2): https://api.labelary.com/v1/printers/8dpmm/labels/3.0x2.0/2/',
  );
  print('');

  // Example 6: QR Code
  print('6. QR Code Label:');
  final qrCommands = [
    const ZplConfiguration(
      printWidth: 406,
      labelLength: 406, // Square label
      printDensity: ZplPrintDensity.d8,
    ),
    const ZplText(x: 50, y: 30, text: 'Scan QR Code:'),
    const ZplBarcode(
      x: 100,
      y: 80,
      data: 'https://example.com/product/12345',
      type: ZplBarcodeType.qrCode,
      height: 100, // QR codes are square, so height = width
    ),
    const ZplText(x: 30, y: 200, text: 'Product ID: 12345'),
  ];
  final qrGenerator = ZplGenerator(qrCommands);
  final qrZpl = qrGenerator.build();
  print('Generated ZPL:');
  print(qrZpl);
  print('URL: https://api.labelary.com/v1/printers/8dpmm/labels/2.0x2.0/0/');
  print('');

  print('=== API Testing URLs ===');
  print('You can test these ZPL scripts by:');
  print('1. Using curl with the Labelary API');
  print('2. Using our LabelaryService.renderZplSimple() method');
  print('3. Pasting the ZPL into the Labelary online viewer');
  print('');
  print('Example curl command:');
  print(
    'curl -X POST "https://api.labelary.com/v1/printers/8dpmm/labels/4x6/0/" \\',
  );
  print('  -H "Accept: image/png" \\');
  print('  -d "\${zpl_content}" \\');
  print('  --output label.png');
  print('');
  print('Labelary online viewer: https://labelary.com/viewer.html');
}
