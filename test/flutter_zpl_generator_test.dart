import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('ZplConfiguration Tests', () {
    test('Empty configuration should produce empty ZPL', () {
      const config = ZplConfiguration();
      expect(config.toZpl(), '');
    });

    test('Configuration with darkness should produce ~SD command', () {
      const config = ZplConfiguration(darkness: 20);
      expect(config.toZpl(), '~SD20\n');
    });

    test('Configuration with label length should produce ^LL command', () {
      const config = ZplConfiguration(labelLength: 800);
      expect(config.toZpl(), '^LL800\n');
    });

    test('Full configuration should produce multiple commands', () {
      const config = ZplConfiguration(
        darkness: 15,
        labelLength: 600,
        labelHomeX: 10,
        labelHomeY: 20,
        printSpeed: 4,
        printMode: ZplPrintMode.tearOff,
      );
      const expectedZpl =
          '~SD15\n'
          '^LL600\n'
          '^LH10,20\n'
          '^PR4\n'
          '^MMT\n';
      expect(config.toZpl(), expectedZpl);
    });
  });

  group('ZplText Tests', () {
    test('Basic ZplText should generate correct ZPL', () {
      const text = ZplText(x: 50, y: 100, text: 'Hello ZPL');
      const expectedZpl =
          '^FO50,100\n'
          '^A0N,,\n'
          '^FDHello ZPL^FS\n';
      expect(text.toZpl(), expectedZpl);
    });

    test('ZplText with all properties should generate correct ZPL', () {
      const text = ZplText(
        x: 30,
        y: 60,
        text: 'Rotated Text',
        font: ZplFont.a,
        fontHeight: 30,
        fontWidth: 20,
        orientation: ZplOrientation.rotated90,
      );
      const expectedZpl =
          '^FO30,60\n'
          '^AAR,30,20\n'
          '^FDRotated Text^FS\n';
      expect(text.toZpl(), expectedZpl);
    });
  });

  group('ZplBarcode Tests', () {
    test('Basic Code128 barcode should generate correct ZPL', () {
      const barcode = ZplBarcode(x: 50, y: 150, data: '12345ABC', height: 100);
      const expectedZpl =
          '^FO50,150\n'
          '^BCN,100,Y,N,N,A\n'
          '^FD12345ABC^FS\n';
      expect(barcode.toZpl(), expectedZpl);
    });

    test('Barcode with custom module width and ratio should include ^BY', () {
      const barcode = ZplBarcode(
        x: 50,
        y: 150,
        data: '12345ABC',
        height: 100,
        moduleWidth: 3,
        wideBarToNarrowBarRatio: 2.5,
      );
      const expectedZpl =
          '^FO50,150\n'
          '^BY3,2.5\n'
          '^BCN,100,Y,N,N,A\n'
          '^FD12345ABC^FS\n';
      expect(barcode.toZpl(), expectedZpl);
    });
  });

  group('ZplBox Tests', () {
    test('Basic ZplBox should generate correct ZPL', () {
      const box = ZplBox(x: 10, y: 10, width: 100, height: 100);
      expect(box.toZpl(), '^FO10,10^GB100,100,1,B,0^FS');
    });

    test('ZplBox with thickness and rounding should generate correct ZPL', () {
      const box = ZplBox(
        x: 20,
        y: 30,
        width: 200,
        height: 150,
        borderThickness: 5,
        cornerRounding: 4,
      );
      expect(box.toZpl(), '^FO20,30^GB200,150,5,B,4^FS');
    });
  });

  group('ZplImage Tests', () {
    test('ZplImage should generate correct ~DG and ^XG commands', () {
      // Create a simple 8x1 pixel black line image (1 byte of data: 11111111 = 0xFF)
      final imageBytes = Uint8List.fromList([
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
        8,
        0,
        0,
        0,
        1,
        8,
        6,
        0,
        0,
        0,
        31,
        24,
        137,
        102,
        0,
        0,
        0,
        10,
        73,
        68,
        65,
        84,
        120,
        156,
        99,
        248,
        255,
        255,
        63,
        0,
        5,
        254,
        2,
        254,
        167,
        53,
        129,
        122,
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
      ]); // Minimal PNG bytes

      final zplImage = ZplImage(
        x: 10,
        y: 10,
        image: imageBytes,
        graphicName: 'TEST.GRF',
      );

      // We test the command structure, not the entire hex data string for simplicity.
      final zplString = zplImage.toZpl();
      expect(zplString, startsWith('^FO10,10\n~DGTEST.GRF,'));
      expect(zplString, endsWith('\n^XGTEST.GRF,1,1^FS\n'));
    });
  });

  group('ZplFontAsset Tests', () {
    test('ZplFontAsset should generate correct ~DU and ^CW commands', () {
      final fontBytes = Uint8List.fromList([
        0,
        1,
        2,
        3,
        4,
        5,
      ]); // Dummy font data
      final fontAsset = ZplFontAsset(
        alias: 'Q',
        fileName: 'MYFONT.TTF',
        fontData: fontBytes,
      );

      const expectedHex = '000102030405';
      final expectedZpl =
          '~DUE:MYFONT.TTF,6,\n'
          '$expectedHex\n'
          '^CWQ,E:MYFONT.TTF\n';

      expect(fontAsset.toZpl(), expectedZpl);
    });
  });

  group('ZplGenerator Tests', () {
    test('Generator should wrap commands with ^XA and ^XZ', () {
      final generator = ZplGenerator([
        const ZplText(x: 10, y: 10, text: 'Test'),
        const ZplBarcode(x: 10, y: 40, data: '123', height: 50),
      ]);

      const expectedZpl =
          '^XA\n'
          '^FO10,10\n^A0N,,\n^FDTest^FS\n'
          '^FO10,40\n^BCN,50,Y,N,N,A\n^FD123^FS\n'
          '^XZ\n';

      expect(generator.build(), expectedZpl);
    });
  });

  group('Advanced Use Cases', () {
    test('Text in a Box - Product Label', () {
      final generator = ZplGenerator([
        const ZplConfiguration(darkness: 20, labelLength: 400, printWidth: 400),
        // Outer box
        const ZplBox(x: 20, y: 20, width: 360, height: 120, borderThickness: 3),
        // Title box
        const ZplBox(x: 30, y: 30, width: 340, height: 40, borderThickness: 2),
        // Title text
        const ZplText(
          x: 50,
          y: 45,
          text: 'PRODUCT LABEL',
          font: ZplFont.a,
          fontHeight: 20,
          fontWidth: 15,
        ),
        // Product info
        const ZplText(x: 40, y: 85, text: 'SKU: ABC-12345', fontHeight: 12),
        const ZplText(x: 40, y: 105, text: 'Price: \$29.99', fontHeight: 12),
        const ZplText(x: 250, y: 85, text: 'Qty: 100', fontHeight: 12),
        const ZplText(x: 250, y: 105, text: 'Exp: 12/2024', fontHeight: 12),
      ]);

      final zpl = generator.build();
      print('\n=== TEXT IN BOX EXAMPLE ===');
      print(zpl);
      print('===========================\n');

      expect(zpl, contains('^XA'));
      expect(zpl, contains('^XZ'));
      expect(zpl, contains('PRODUCT LABEL'));
    });

    test('Table Layout - Shipping Label', () {
      final generator = ZplGenerator([
        const ZplConfiguration(darkness: 15, labelLength: 600, printWidth: 400),
        // Header
        const ZplText(
          x: 50,
          y: 30,
          text: 'SHIPPING LABEL',
          font: ZplFont.a,
          fontHeight: 25,
          fontWidth: 18,
        ),
        // Main border
        const ZplBox(x: 20, y: 70, width: 360, height: 500, borderThickness: 2),

        // From section
        const ZplText(
          x: 30,
          y: 85,
          text: 'FROM:',
          fontHeight: 14,
          font: ZplFont.b,
        ),
        const ZplBox(x: 30, y: 105, width: 340, height: 80, borderThickness: 1),
        const ZplText(x: 40, y: 115, text: 'Acme Corp', fontHeight: 12),
        const ZplText(x: 40, y: 135, text: '123 Business St', fontHeight: 12),
        const ZplText(
          x: 40,
          y: 155,
          text: 'New York, NY 10001',
          fontHeight: 12,
        ),

        // To section
        const ZplText(
          x: 30,
          y: 200,
          text: 'TO:',
          fontHeight: 14,
          font: ZplFont.b,
        ),
        const ZplBox(x: 30, y: 220, width: 340, height: 80, borderThickness: 1),
        const ZplText(x: 40, y: 230, text: 'John Smith', fontHeight: 12),
        const ZplText(x: 40, y: 250, text: '456 Customer Ave', fontHeight: 12),
        const ZplText(
          x: 40,
          y: 270,
          text: 'Los Angeles, CA 90210',
          fontHeight: 12,
        ),

        // Tracking section
        const ZplText(
          x: 30,
          y: 320,
          text: 'TRACKING:',
          fontHeight: 14,
          font: ZplFont.b,
        ),
        const ZplBox(x: 30, y: 340, width: 340, height: 40, borderThickness: 1),
        const ZplText(
          x: 40,
          y: 355,
          text: '1Z999AA1234567890',
          fontHeight: 16,
          font: ZplFont.a,
        ),

        // Barcode
        const ZplBarcode(
          x: 50,
          y: 400,
          data: '1Z999AA1234567890',
          height: 80,
          type: ZplBarcodeType.code128,
        ),

        // Weight and service
        const ZplBox(x: 30, y: 500, width: 170, height: 50, borderThickness: 1),
        const ZplText(x: 40, y: 515, text: 'Weight: 2.5 lbs', fontHeight: 12),
        const ZplText(x: 40, y: 535, text: 'Service: Ground', fontHeight: 12),

        const ZplBox(
          x: 200,
          y: 500,
          width: 170,
          height: 50,
          borderThickness: 1,
        ),
        const ZplText(x: 210, y: 515, text: 'Date: 03/15/2024', fontHeight: 12),
        const ZplText(x: 210, y: 535, text: 'Zone: 5', fontHeight: 12),
      ]);

      final zpl = generator.build();
      print('\n=== TABLE LAYOUT EXAMPLE ===');
      print(zpl);
      print('============================\n');

      expect(zpl, contains('SHIPPING LABEL'));
      expect(zpl, contains('1Z999AA1234567890'));
    });

    test('Receipt Layout with Row/Column', () {
      final generator = ZplGenerator([
        const ZplConfiguration(darkness: 18, labelLength: 800, printWidth: 300),
        // Store header
        const ZplText(
          x: 75,
          y: 30,
          text: 'ACME STORE',
          font: ZplFont.a,
          fontHeight: 20,
          fontWidth: 15,
        ),
        const ZplText(x: 85, y: 55, text: '123 Main St', fontHeight: 10),
        const ZplText(x: 75, y: 70, text: 'City, ST 12345', fontHeight: 10),

        // Separator line
        const ZplBox(x: 20, y: 90, width: 260, height: 2, borderThickness: 2),

        // Receipt header
        const ZplText(x: 20, y: 110, text: 'Receipt #: 001234', fontHeight: 12),
        const ZplText(
          x: 20,
          y: 130,
          text: 'Date: 03/15/2024 14:30',
          fontHeight: 12,
        ),

        // Items header
        const ZplBox(x: 20, y: 150, width: 260, height: 2, borderThickness: 1),

        // Using ZplRow for item layout
        ZplRow(
          x: 20,
          y: 170,
          spacing: 10,
          children: const [
            ZplText(text: 'Item', fontHeight: 12, font: ZplFont.b, x: 0, y: 0),
            ZplText(text: 'Qty', fontHeight: 12, font: ZplFont.b, x: 0, y: 0),
            ZplText(text: 'Price', fontHeight: 12, font: ZplFont.b, x: 0, y: 0),
          ],
        ),

        // Item 1
        ZplRow(
          x: 20,
          y: 190,
          spacing: 10,
          children: const [
            ZplText(text: 'Coffee', fontHeight: 10, x: 0, y: 0),
            ZplText(text: '2', fontHeight: 10, x: 0, y: 0),
            ZplText(text: '\$8.00', fontHeight: 10, x: 0, y: 0),
          ],
        ),

        // Item 2
        ZplRow(
          x: 20,
          y: 210,
          spacing: 10,
          children: const [
            ZplText(text: 'Sandwich', fontHeight: 10, x: 0, y: 0),
            ZplText(text: '1', fontHeight: 10, x: 0, y: 0),
            ZplText(text: '\$12.50', fontHeight: 10, x: 0, y: 0),
          ],
        ),

        // Separator
        const ZplBox(x: 20, y: 230, width: 260, height: 1, borderThickness: 1),

        // Total
        const ZplText(
          x: 180,
          y: 250,
          text: 'Total: \$20.50',
          fontHeight: 14,
          font: ZplFont.b,
        ),

        // QR Code for digital receipt
        const ZplText(
          x: 20,
          y: 280,
          text: 'Scan for digital receipt:',
          fontHeight: 10,
        ),
        const ZplBarcode(
          x: 20,
          y: 300,
          data: 'https://store.com/receipt/001234',
          type: ZplBarcodeType.qrCode,
          height: 60,
        ),

        // Footer
        const ZplText(x: 70, y: 380, text: 'Thank you!', fontHeight: 12),
      ]);

      final zpl = generator.build();
      print('\n=== RECEIPT LAYOUT EXAMPLE ===');
      print(zpl);
      print('==============================\n');

      expect(zpl, contains('ACME STORE'));
      expect(zpl, contains('Receipt #: 001234'));
      expect(zpl, contains('Total: \$20.50'));
    });

    test('Badge/ID Card Layout', () {
      final generator = ZplGenerator([
        const ZplConfiguration(
          darkness: 20,
          labelLength: 400,
          printWidth: 600,
          printOrientation: ZplPrintOrientation.normal,
        ),
        // Main card border
        const ZplBox(x: 50, y: 50, width: 500, height: 300, borderThickness: 4),

        // Header section
        const ZplBox(x: 60, y: 60, width: 480, height: 60, borderThickness: 2),
        const ZplText(
          x: 250,
          y: 80,
          text: 'EMPLOYEE BADGE',
          font: ZplFont.a,
          fontHeight: 18,
          fontWidth: 12,
        ),

        // Photo placeholder
        const ZplBox(
          x: 80,
          y: 140,
          width: 100,
          height: 120,
          borderThickness: 2,
        ),
        const ZplText(x: 115, y: 190, text: 'PHOTO', fontHeight: 12),

        // Employee info
        const ZplText(
          x: 200,
          y: 150,
          text: 'Name:',
          fontHeight: 12,
          font: ZplFont.b,
        ),
        const ZplText(x: 250, y: 150, text: 'John Doe', fontHeight: 12),

        const ZplText(
          x: 200,
          y: 170,
          text: 'ID:',
          fontHeight: 12,
          font: ZplFont.b,
        ),
        const ZplText(x: 250, y: 170, text: 'EMP001', fontHeight: 12),

        const ZplText(
          x: 200,
          y: 190,
          text: 'Dept:',
          fontHeight: 12,
          font: ZplFont.b,
        ),
        const ZplText(x: 250, y: 190, text: 'Engineering', fontHeight: 12),

        const ZplText(
          x: 200,
          y: 210,
          text: 'Level:',
          fontHeight: 12,
          font: ZplFont.b,
        ),
        const ZplText(x: 250, y: 210, text: 'Senior', fontHeight: 12),

        const ZplText(
          x: 200,
          y: 230,
          text: 'Valid:',
          fontHeight: 12,
          font: ZplFont.b,
        ),
        const ZplText(x: 250, y: 230, text: '12/31/2024', fontHeight: 12),

        // Access code barcode
        const ZplText(x: 80, y: 280, text: 'Access Code:', fontHeight: 10),
        const ZplBarcode(
          x: 200,
          y: 275,
          data: 'EMP001',
          height: 40,
          type: ZplBarcodeType.code39,
          printInterpretationLine: false,
        ),

        // Footer
        const ZplText(x: 200, y: 330, text: 'Acme Corporation', fontHeight: 10),
      ]);

      final zpl = generator.build();
      print('\n=== BADGE/ID CARD EXAMPLE ===');
      print(zpl);
      print('=============================\n');

      expect(zpl, contains('EMPLOYEE BADGE'));
      expect(zpl, contains('John Doe'));
      expect(zpl, contains('Engineering'));
    });

    test('Print Density Examples for Online Validation', () {
      // Test different densities that match online ZPL viewers
      final densities = [
        ZplPrintDensity.dpi152, // 6dpmm
        ZplPrintDensity.dpi203, // 8dpmm (most common)
        ZplPrintDensity.dpi300, // 12dpmm
        ZplPrintDensity.dpi600, // 24dpmm
      ];

      for (final density in densities) {
        final generator = ZplGenerator([
          ZplConfiguration(
            darkness: 15,
            labelLength: 400,
            printWidth: 600,
            printDensity: density,
          ),
          ZplText(
            x: 50,
            y: 50,
            text: 'Density Test: ${density.dpi} DPI',
            font: ZplFont.a,
            fontHeight: 20,
          ),
          ZplText(
            x: 50,
            y: 80,
            text: '${density.dotsPerMm} dots per mm',
            fontHeight: 12,
          ),
          const ZplBox(
            x: 50,
            y: 110,
            width: 300,
            height: 100,
            borderThickness: 2,
          ),
          const ZplText(
            x: 60,
            y: 130,
            text: 'This box should be consistent',
            fontHeight: 12,
          ),
          const ZplText(
            x: 60,
            y: 150,
            text: 'across different densities',
            fontHeight: 12,
          ),
          ZplBarcode(
            x: 60,
            y: 180,
            data: 'DENSITY${density.dpi}',
            height: 40,
            type: ZplBarcodeType.code128,
          ),
        ]);

        final zpl = generator.build();
        print(
          '\n=== ${density.dpi} DPI (${density.dotsPerMm}dpmm) EXAMPLE ===',
        );
        print(
          'Use this setting in online ZPL viewer: ${density.dotsPerMm}dpmm',
        );
        print(zpl);
        print('${'=' * 50}\n');

        expect(zpl, contains('^JM${density.value}'));
        expect(zpl, contains('${density.dpi} DPI'));
      }
    });

    test('Optimized Label for 203 DPI (Most Common)', () {
      // 203 DPI is the most common printer resolution
      final generator = ZplGenerator([
        const ZplConfiguration(
          darkness: 18,
          labelLength: 600,
          printWidth: 600, // Increased to accommodate content
          printDensity: ZplPrintDensity.dpi203, // 8dpmm
        ),
        // Title optimized for 203 DPI - shorter text
        const ZplText(
          x: 50,
          y: 30,
          text: '203 DPI PRODUCT LABEL',
          font: ZplFont.a,
          fontHeight: 20,
          fontWidth: 15,
        ),
        // Content box sized for 203 DPI (approximately 2.5" x 1.5")
        const ZplBox(x: 20, y: 70, width: 560, height: 255, borderThickness: 3),

        // Product info section
        const ZplText(
          x: 40,
          y: 100,
          text: 'Product: Sample Item',
          fontHeight: 14,
        ),
        const ZplText(x: 40, y: 125, text: 'SKU: PRD-2024-001', fontHeight: 14),
        const ZplText(x: 40, y: 150, text: 'Price: \$45.99', fontHeight: 14),

        // Barcode optimized for 203 DPI
        const ZplBarcode(
          x: 40,
          y: 190,
          data: 'PRD2024001',
          height: 60,
          type: ZplBarcodeType.code128,
          moduleWidth: 2, // Optimal for 203 DPI
        ),

        // Footer
        const ZplText(
          x: 40,
          y: 280,
          text: 'Scan above for details',
          fontHeight: 10,
        ),
      ]);

      final zpl = generator.build();
      print('\n=== OPTIMIZED FOR 203 DPI (8dpmm) ===');
      print('This label is sized for 3" x 3" at 203 DPI');
      print('Use 8dpmm (203dpi) setting in online viewer');
      print(zpl);
      print('=====================================\n');

      expect(zpl, contains('^JMB')); // 203 DPI setting
      expect(zpl, contains('203 DPI PRODUCT LABEL'));
    });

    test('Compact 2x1 inch Label (203 DPI)', () {
      // A smaller label that fits perfectly in 2" x 1" dimensions
      final generator = ZplGenerator([
        const ZplConfiguration(
          darkness: 18,
          labelLength: 203, // 1 inch at 203 DPI
          printWidth: 406, // 2 inches at 203 DPI
          printDensity: ZplPrintDensity.dpi203,
        ),
        // Compact title
        const ZplText(
          x: 10,
          y: 10,
          text: 'PRODUCT TAG',
          font: ZplFont.b,
          fontHeight: 16,
        ),
        // Main content area
        const ZplBox(x: 5, y: 35, width: 396, height: 160, borderThickness: 2),

        // Product info in two columns
        const ZplText(x: 15, y: 50, text: 'SKU: ABC123', fontHeight: 12),
        const ZplText(x: 15, y: 70, text: 'Price: \$19.99', fontHeight: 12),

        // Compact barcode
        const ZplBarcode(
          x: 200,
          y: 45,
          data: 'ABC123',
          height: 40,
          type: ZplBarcodeType.code128,
          moduleWidth: 2,
          printInterpretationLine: false,
        ),

        // Bottom info
        const ZplText(x: 15, y: 170, text: 'Qty: 50', fontHeight: 10),
        const ZplText(x: 300, y: 170, text: 'LOT: 2024A', fontHeight: 10),
      ]);

      final zpl = generator.build();
      print('\n=== COMPACT 2x1 INCH LABEL (203 DPI) ===');
      print('Perfect fit for 2" x 1" label at 203 DPI');
      print('Dimensions: 406x203 dots = 2"x1" at 203 DPI');
      print('Use 8dpmm (203dpi) setting in online viewer');
      print(zpl);
      print('=========================================\n');

      expect(zpl, contains('^JMB'));
      expect(zpl, contains('PRODUCT TAG'));
    });
  });
}
