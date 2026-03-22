import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'demo_scaffold.dart';

class BarcodeDemo extends StatelessWidget {
  const BarcodeDemo({super.key});

  static const _config = ZplConfiguration(
    printWidth: 812,
    labelLength: 1400,
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
    ];
  }
}
