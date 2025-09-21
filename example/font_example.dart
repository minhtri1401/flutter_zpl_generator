import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

/// Example demonstrating how to use custom TTF fonts with the ZPL generator.
///
/// This example shows the complete workflow:
/// 1. Creating font assets
/// 2. Using the asset service to generate font upload commands
/// 3. Using custom fonts in text elements
/// 4. Generating the complete ZPL with font uploads
void main() async {
  // Step 1: Create font asset definitions
  // Note: You need to add these font files to your Flutter assets first
  final robotoRegular = ZplFontAsset(
    assetPath: 'assets/fonts/Roboto-Regular.ttf',
    identifier: 'A',
    displayName: 'Roboto Regular',
  );

  final robotoBold = ZplFontAsset(
    assetPath: 'assets/fonts/Roboto-Bold.ttf',
    identifier: 'B',
    displayName: 'Roboto Bold',
  );

  // Step 2: Create your label commands using custom fonts
  final commands = [
    const ZplConfiguration(
      printWidth: 576, // 2.25 inches at 203 DPI
      labelLength: 400,
      printDensity: ZplPrintDensity.d8,
    ),

    // Header with bold font
    ZplText(
      x: 50,
      y: 50,
      text: 'CUSTOM FONT DEMO',
      fontHeight: 32,
      fontWidth: 28,
      customFont: robotoBold, // Using custom bold font
    ),

    // Body text with regular font
    ZplText(
      x: 50,
      y: 100,
      text: 'This text uses Roboto Regular font',
      fontHeight: 20,
      fontWidth: 18,
      customFont: robotoRegular, // Using custom regular font
    ),

    // Comparison with default ZPL font
    ZplText(
      x: 50,
      y: 140,
      text: 'This text uses default ZPL bitmap font',
      fontHeight: 20,
      fontWidth: 18,
      // No customFont specified = uses default bitmap font
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

    // Table example with custom fonts
    ZplTable(
      y: 260,
      columnWidths: [8, 4], // Simple 2-column layout
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

  // Step 3: Create the generator with font assets
  final generator = ZplGenerator(
    commands,
    fonts: [robotoRegular, robotoBold], // Specify which fonts to upload
    // assetService: ZplAssetService(), // Optional: provide custom service
  );

  // Step 4: Generate the complete ZPL (including font uploads)
  final zplString = await generator.build(); // Note: now async!

  print('Generated ZPL with custom fonts:');
  print('=' * 50);
  print(zplString);
  print('=' * 50);

  // The generated ZPL will include:
  // 1. ^XA (start of label)
  // 2. ~DY commands to upload font files
  // 3. Your label commands using the uploaded fonts
  // 4. ^XZ (end of label)
}

/// Example showing manual font upload (if you need more control)
void manualFontUploadExample() async {
  // Create the asset service
  final assetService = ZplAssetService();

  // Create a font asset
  final customFont = ZplFontAsset(
    assetPath: 'assets/fonts/MyFont.ttf',
    identifier: 'C',
  );

  // Generate the upload command manually
  final uploadCommand = await assetService.getFontUploadCommand(customFont);

  print('Manual font upload command:');
  print(uploadCommand);

  // You can then include this in your ZPL manually if needed
  final manualZpl =
      '''
^XA
$uploadCommand
^FO50,50
^A@N,24,20,${customFont.printerPath}
^FDCustom font text^FS
^XZ
''';

  print('\nManual ZPL:');
  print(manualZpl);
}

/// Example showing font asset validation
void fontValidationExample() async {
  final assetService = ZplAssetService();

  // Check if a font asset exists before using it
  final exists = await assetService.validateAssetPath(
    'assets/fonts/Roboto-Regular.ttf',
  );

  if (exists) {
    print('Font asset found and can be loaded');
  } else {
    print('Font asset not found - check your pubspec.yaml and file path');
  }
}
