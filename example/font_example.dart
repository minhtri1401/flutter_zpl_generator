import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

/// Example demonstrating how to use custom TTF fonts with the v2.0
/// ZPL generator.
///
/// v2.0 workflow:
/// 1. Load font bytes via `ZplFontUpload.fromAsset(path, identifier)`
/// 2. Pass the `ZplFontUpload` in `commands:` — it emits `~DY` BEFORE `^XA`
///    automatically (required on Link-OS mobile printers).
/// 3. Reference it on any `ZplText` via `customFont:`.
void main() async {
  // Step 1: Load font assets (requires a Flutter runtime — asset bundle).
  final robotoRegular = await ZplFontUpload.fromAsset(
    'assets/fonts/Roboto-Regular.ttf',
    'A',
  );

  final robotoBold = await ZplFontUpload.fromAsset(
    'assets/fonts/Roboto-Bold.ttf',
    'B',
  );

  // Step 2: Build the label with font uploads at the top of `commands`.
  final commands = <ZplCommand>[
    robotoRegular, // ~DY upload (pre-^XA)
    robotoBold, // ~DY upload (pre-^XA)

    // Header with bold font
    ZplText(
      x: 50,
      y: 50,
      text: 'CUSTOM FONT DEMO',
      fontHeight: 32,
      fontWidth: 28,
      customFont: robotoBold,
    ),

    // Body text with regular font
    ZplText(
      x: 50,
      y: 100,
      text: 'This text uses Roboto Regular font',
      fontHeight: 20,
      fontWidth: 18,
      customFont: robotoRegular,
    ),

    // Comparison with default ZPL font
    ZplText(
      x: 50,
      y: 140,
      text: 'This text uses default ZPL bitmap font',
      fontHeight: 20,
      fontWidth: 18,
    ),

    // Multi-line text with custom font
    ZplText(
      x: 50,
      y: 180,
      text:
          'This is a longer text that demonstrates how custom fonts work with text wrapping and multiple lines.',
      fontHeight: 18,
      fontWidth: 16,
      maxLines: 3,
      lineSpacing: 2,
      customFont: robotoRegular,
    ),

    // Table example
    ZplTable(
      y: 260,
      columnWidths: [8, 4],
      borderThickness: 1,
      cellPadding: 4,
      headers: [
        ZplTableHeader(
          'Product',
          alignment: ZplAlignment.left,
          fontHeight: 18,
          fontWidth: 16,
        ),
        ZplTableHeader(
          'Price',
          alignment: ZplAlignment.right,
          fontHeight: 18,
          fontWidth: 16,
        ),
      ],
      data: [
        ['Custom Font Item 1', '\$19.99'],
        ['Custom Font Item 2', '\$24.50'],
      ],
      dataFontHeight: 16,
      dataFontWidth: 14,
    ),
  ];

  // Step 3: Build the ZPL.
  final generator = ZplGenerator(
    config: const ZplConfiguration(
      printWidth: 576,
      labelLength: 400,
      printDensity: ZplPrintDensity.d8,
    ),
    commands: commands,
  );

  final zplString = await generator.build();

  print('Generated ZPL with custom fonts:');
  print('=' * 50);
  print(zplString);
  print('=' * 50);

  // The emitted ZPL will include (in order):
  // 1. ~DY upload for Roboto-Regular
  // 2. ~DY upload for Roboto-Bold
  // 3. ^XA  (start of label)
  // 4. Format commands using the uploaded fonts
  // 5. ^XZ  (end of label)
}

/// Validate a font asset before trying to load it.
Future<void> fontValidationExample() async {
  final assetService = ZplAssetService();
  final exists = await assetService.validateAssetPath(
    'assets/fonts/Roboto-Regular.ttf',
  );
  if (exists) {
    print('Font asset found and can be loaded');
  } else {
    print('Font asset not found - check your pubspec.yaml and file path');
  }
}
