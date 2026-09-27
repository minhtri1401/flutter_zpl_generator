import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'demo_scaffold.dart';

class BarcodeDemo extends StatelessWidget {
  const BarcodeDemo({super.key});

  static const _config = ZplConfiguration(
    printWidth: 812,
    labelLength: 1720,
    printDensity: ZplPrintDensity.d8,
  );

  @override
  Widget build(BuildContext context) {
    final generator = ZplGenerator(config: _config, commands: _buildCommands());

    return DemoScaffold(
      title: 'Barcode Types',
      generator: generator,
      features: const [
        'Code 128 - general purpose alphanumeric',
        'Code 39 - older alphanumeric standard',
        'QR Code - 2D matrix barcode',
        'DataMatrix - 2D compact matrix (^BX)',
        'EAN-13 - European Article Number (^BE)',
        'UPC-A - Universal Product Code (^BU)',
        'GS1-128 (^BC mode D), PDF417 (^B7), Aztec (^BO) - v2.1',
        'Code 93 (^BA), I2of5 (^B2), EAN-8 (^B8), UPC-E (^B9) - v2.1',
        'magnification / qrErrorCorrection - QR & Aztec sizing',
        'moduleWidth - controls bar thickness',
        'printInterpretationLine - human-readable text below',
        'alignment - center/right aligned barcodes',
      ],
    );
  }

  List<ZplCommand> _buildCommands() {
    return [
      // Title
      ZplText(
        x: 0,
        y: 20,
        text: 'BARCODE TYPES',
        fontHeight: 40,
        fontWidth: 36,
        alignment: ZplAlignment.center,
      ),
      ZplSeparator(y: 75, thickness: 2),

      // Code 128
      ZplText(x: 20, y: 100, text: 'Code 128:', fontHeight: 20, fontWidth: 16),
      ZplBarcode(
        x: 20,
        y: 130,
        data: 'ABC-12345',
        type: ZplBarcodeType.code128,
        height: 80,
        moduleWidth: 2,
      ),

      // Code 39
      ZplText(x: 20, y: 250, text: 'Code 39:', fontHeight: 20, fontWidth: 16),
      ZplBarcode(
        x: 20,
        y: 280,
        data: 'CODE39TEST',
        type: ZplBarcodeType.code39,
        height: 80,
        moduleWidth: 2,
      ),

      ZplSeparator(y: 410, thickness: 1),

      // QR Code
      ZplText(x: 20, y: 435, text: 'QR Code:', fontHeight: 20, fontWidth: 16),
      ZplBarcode(
        x: 20,
        y: 465,
        data: 'https://pub.dev/packages/flutter_zpl_generator',
        type: ZplBarcodeType.qrCode,
        height: 150,
      ),

      // DataMatrix (next to QR)
      ZplText(
        x: 420,
        y: 435,
        text: 'DataMatrix:',
        fontHeight: 20,
        fontWidth: 16,
      ),
      ZplBarcode(
        x: 420,
        y: 465,
        data: 'DM-SAMPLE-2024',
        type: ZplBarcodeType.dataMatrix,
        height: 6, // module size, not total height
      ),

      ZplSeparator(y: 660, thickness: 1),

      // EAN-13
      ZplText(x: 20, y: 685, text: 'EAN-13:', fontHeight: 20, fontWidth: 16),
      ZplBarcode(
        x: 20,
        y: 715,
        data: '5901234123457',
        type: ZplBarcodeType.ean13,
        height: 100,
        moduleWidth: 3,
      ),

      // UPC-A
      ZplText(x: 420, y: 685, text: 'UPC-A:', fontHeight: 20, fontWidth: 16),
      ZplBarcode(
        x: 420,
        y: 715,
        data: '01234567890',
        type: ZplBarcodeType.upcA,
        height: 100,
        moduleWidth: 3,
      ),

      ZplSeparator(y: 870, thickness: 1),

      // Center-aligned barcode
      ZplText(
        x: 0,
        y: 895,
        text: 'Center-aligned barcode:',
        fontHeight: 20,
        fontWidth: 16,
        alignment: ZplAlignment.center,
      ),
      ZplBarcode(
        x: 0,
        y: 930,
        data: 'CENTERED-123',
        type: ZplBarcodeType.code128,
        height: 80,
        moduleWidth: 2,
        alignment: ZplAlignment.center,
      ),

      // No interpretation line
      ZplText(
        x: 20,
        y: 1060,
        text: 'No interpretation line:',
        fontHeight: 20,
        fontWidth: 16,
      ),
      ZplBarcode(
        x: 20,
        y: 1090,
        data: 'NOTEXT',
        type: ZplBarcodeType.code128,
        height: 60,
        moduleWidth: 2,
        printInterpretationLine: false,
      ),

      // Interpretation line above
      ZplText(
        x: 420,
        y: 1060,
        text: 'Interpretation above:',
        fontHeight: 20,
        fontWidth: 16,
      ),
      ZplBarcode(
        x: 420,
        y: 1120,
        data: 'ABOVE',
        type: ZplBarcodeType.code128,
        height: 60,
        moduleWidth: 2,
        printInterpretationLineAbove: true,
      ),

      ZplSeparator(y: 1230, thickness: 1),

      // v2.1 symbologies
      ZplText(x: 20, y: 1255, text: 'GS1-128:', fontHeight: 20, fontWidth: 16),
      ZplBarcode(
        x: 20,
        y: 1285,
        data: '(01)09501101530003(17)261231',
        type: ZplBarcodeType.gs1_128,
        height: 70,
        moduleWidth: 2,
      ),
      ZplText(x: 420, y: 1255, text: 'PDF417:', fontHeight: 20, fontWidth: 16),
      ZplBarcode(
        x: 420,
        y: 1285,
        data: 'Stacked 2D payload',
        type: ZplBarcodeType.pdf417,
        height: 6,
        pdf417Columns: 4,
        pdf417SecurityLevel: 2,
      ),
      ZplText(x: 20, y: 1410, text: 'Aztec:', fontHeight: 20, fontWidth: 16),
      ZplBarcode(
        x: 20,
        y: 1440,
        data: 'AZTEC-2026',
        type: ZplBarcodeType.aztec,
        height: 0,
        magnification: 4,
      ),
      ZplText(
        x: 420,
        y: 1410,
        text: 'EAN-8 / UPC-E:',
        fontHeight: 20,
        fontWidth: 16,
      ),
      ZplBarcode(
        x: 420,
        y: 1440,
        data: '9638507',
        type: ZplBarcodeType.ean8,
        height: 60,
        moduleWidth: 2,
      ),
      ZplBarcode(
        x: 620,
        y: 1440,
        data: '1234567',
        type: ZplBarcodeType.upcE,
        height: 60,
        moduleWidth: 2,
      ),
      ZplText(
        x: 20,
        y: 1560,
        text: 'Code 93 / I2of5:',
        fontHeight: 20,
        fontWidth: 16,
      ),
      ZplBarcode(
        x: 20,
        y: 1590,
        data: 'CODE93',
        type: ZplBarcodeType.code93,
        height: 60,
        moduleWidth: 2,
      ),
      ZplBarcode(
        x: 420,
        y: 1590,
        data: '12345678',
        type: ZplBarcodeType.interleaved2of5,
        height: 60,
        moduleWidth: 2,
      ),
    ];
  }
}
