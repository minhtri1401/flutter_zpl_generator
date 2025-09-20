# Flutter ZPL Generator

A comprehensive Flutter package for generating ZPL (Zebra Programming Language) labels with **industry-first TTF font conversion** and **automatic image-to-ZPL conversion** capabilities.

[![pub package](https://img.shields.io/pub/v/flutter_zpl_generator.svg)](https://pub.dev/packages/flutter_zpl_generator)
[![popularity](https://img.shields.io/pub/popularity/flutter_zpl_generator?logo=dart)](https://pub.dev/packages/flutter_zpl_generator/score)
[![likes](https://img.shields.io/pub/likes/flutter_zpl_generator?logo=dart)](https://pub.dev/packages/flutter_zpl_generator/score)
[![pub points](https://img.shields.io/pub/points/flutter_zpl_generator?logo=dart)](https://pub.dev/packages/flutter_zpl_generator/score)

## 🌟 **What Makes This Package Special**

### 🔤 **TTF to ZPL Font Conversion** (First in Flutter!)
- Convert any TrueType font to ZPL format
- Upload custom fonts directly to your Zebra printer's memory
- Use your brand fonts in labels for perfect consistency
- No more limitations to basic printer fonts

### 📸 **Automatic Image to ZPL Graphics**
- Convert PNG, JPEG, GIF images to ZPL graphics
- Automatic dithering and optimization for thermal printing
- Embed company logos, photos, and graphics directly in labels
- Memory-efficient printer storage options

### 🖼️ **Live Flutter Preview**
- See exactly how your labels will print
- Real-time preview as you build
- No need for physical printer during development

### ⚡ **Quick Example: Custom Font Label**

```dart
// 1. Convert your TTF font to ZPL
final fontBytes = await loadFont('assets/fonts/Roboto-Bold.ttf');
final zplFont = await LabelaryService.convertFontToZpl(fontBytes, 'Roboto-Bold.ttf', name: 'R');

// 2. Use it in your label with live preview
final commands = [
  ZplFontAsset(alias: 'R', fileName: 'ROBOTO.TTF', fontData: fontBytes),
  const ZplText(x: 20, y: 20, text: 'Beautiful Custom Font!', fontAlias: 'R', fontHeight: 30),
  const ZplBarcode(x: 20, y: 70, data: '12345', height: 50),
];

// 3. See it live in Flutter
Widget build(context) => ZplPreview(generator: ZplGenerator(commands));
```

## Features

- 🏷️ **Complete ZPL Support**: Text, barcodes, images, boxes, and layout components
- 🖼️ **Live Preview**: Built-in `ZplPreview` widget for real-time label visualization
- 🌐 **Labelary Integration**: Full API support with advanced features (rotation, PDF options, linting)
- 🔤 **🌟 TTF Font Conversion**: Convert TrueType fonts to ZPL and use them directly on your printer
- 📸 **🌟 Image to ZPL Conversion**: Automatically convert images (PNG, JPEG) to ZPL graphics
- 📱 **Cross-Platform**: Works on iOS, Android, Web, macOS, Windows, and Linux
- 🎯 **Type-Safe**: Strongly typed ZPL command generation
- 🔧 **Flexible**: Extensive customization options for all label elements
- ⚡ **Performance**: Optimized for efficient label generation and rendering

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_zpl_generator: ^1.0.0
```

Then run:

```bash
flutter pub get
```

## Quick Start

### Basic Label Generation

```dart
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

// Create ZPL commands
final commands = [
  const ZplConfiguration(
    printWidth: 406, // 2 inches at 203 DPI
    labelLength: 203, // 1 inch at 203 DPI
    printDensity: ZplPrintDensity.d8,
  ),
  const ZplText(x: 20, y: 20, text: 'Hello World!'),
  const ZplBarcode(x: 20, y: 60, height: 50, data: '12345'),
];

// Generate ZPL string
final generator = ZplGenerator(commands);
final zplString = generator.build();
print(zplString);
// Output: ^XA^LL203^PR8^JMB^FO20,20^A0N,,...^XZ
```

### Live Preview Widget

```dart
import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

class LabelPreviewScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final commands = [
      const ZplConfiguration(
        printWidth: 406,
        labelLength: 203,
        printDensity: ZplPrintDensity.d8,
      ),
      const ZplText(x: 20, y: 20, text: 'Product Label'),
      const ZplBarcode(x: 20, y: 60, height: 50, data: '123456789'),
    ];
    
    final generator = ZplGenerator(commands);

    return Scaffold(
      appBar: AppBar(title: Text('Label Preview')),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
          ),
          child: ZplPreview(generator: generator),
        ),
      ),
    );
  }
}
```

## Core Components

### ZPL Commands

| Component | Description | Example |
|-----------|-------------|---------|
| `ZplConfiguration` | Label setup (size, density, orientation) | `ZplConfiguration(printWidth: 406, labelLength: 203)` |
| `ZplText` | Text rendering with fonts and formatting | `ZplText(x: 10, y: 10, text: 'Hello')` |
| `ZplBarcode` | Various barcode types (Code128, QR, etc.) | `ZplBarcode(x: 10, y: 50, data: '12345')` |
| `ZplImage` | Image embedding and positioning | `ZplImage(x: 10, y: 10, imageData: bytes)` |
| `ZplBox` | Rectangles and borders | `ZplBox(x: 5, y: 5, width: 100, height: 50)` |

### Layout Components

```dart
// Horizontal layout
ZplRow(
  x: 10, y: 20,
  spacing: 50,
  children: [
    ZplText(text: 'Col 1'),
    ZplText(text: 'Col 2'),
  ],
)

// Vertical layout
ZplColumn(
  x: 10, y: 20,
  spacing: 30,
  children: [
    ZplText(text: 'Row 1'),
    ZplText(text: 'Row 2'),
  ],
)
```

## Advanced Features

### Labelary API Integration

```dart
// Basic rendering
final response = await LabelaryService.renderZpl(zplString);
final imageBytes = response.data;

// Advanced rendering with options
final response = await LabelaryService.renderZpl(
  zplString,
  outputFormat: LabelaryOutputFormat.pdf,
  rotation: LabelaryRotation.rotate90,
  pageSize: LabelaryPageSize.a4,
  enableLinting: true,
);

// Check for warnings
if (response.warnings.isNotEmpty) {
  for (final warning in response.warnings) {
    print('Warning: ${warning.message}');
  }
}
```

## 🌟 **Unique Features: TTF Font & Image Conversion**

### Import Custom Fonts to Your Printer

One of the standout features of this package is the ability to **convert TrueType fonts (TTF) to ZPL format** and upload them directly to your Zebra printer's memory. This allows you to use custom fonts in your labels without relying on the printer's built-in fonts.

#### Step 1: Convert TTF Font to ZPL

```dart
import 'dart:io';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

// Load your TTF font file
final fontFile = File('assets/fonts/Roboto-Regular.ttf');
final fontBytes = await fontFile.readAsBytes();

// Convert TTF to ZPL format
final zplFontData = await LabelaryService.convertFontToZpl(
  fontBytes,
  'Roboto-Regular.ttf',
  name: 'R', // Single letter alias for the font
  fontSize: 12, // Optional: specify font size
);

print('ZPL Font Data: $zplFontData');
// This outputs ZPL commands that upload the font to printer memory
```

#### Step 2: Use the Font Asset in Your Labels

```dart
// Method 1: Use ZplFontAsset to include font in your label
final commands = [
  ZplFontAsset(
    alias: 'R',
    fileName: 'ROBOTO.TTF',
    fontData: fontBytes,
  ),
  const ZplText(
    x: 50, y: 100,
    text: 'Custom Font Text!',
    fontAlias: 'R', // Use your custom font
    fontHeight: 25,
  ),
];

// Method 2: Send font to printer first, then use in any label
// Send the ZPL font data to your printer once:
await sendToPrinter(zplFontData); // Your printer communication code

// Then use the font in any subsequent labels:
final quickLabel = ZplGenerator([
  const ZplText(
    x: 20, y: 20,
    text: 'Using uploaded font!',
    fontAlias: 'R', // References the font already in printer memory
    fontHeight: 30,
  ),
]);
```

#### Real-World Font Usage Example

```dart
class CustomFontLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: loadFontFromAssets('fonts/YourCustomFont.ttf'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final fontBytes = snapshot.data!;
        final commands = [
          const ZplConfiguration(printWidth: 406, labelLength: 609),
          
          // Upload custom font to printer
          ZplFontAsset(
            alias: 'C',
            fileName: 'CUSTOM.TTF',
            fontData: fontBytes,
          ),
          
          // Use the custom font
          const ZplText(
            x: 30, y: 50,
            text: 'Beautiful Custom Typography',
            fontAlias: 'C',
            fontHeight: 35,
          ),
          
          // Mix with standard fonts
          const ZplText(
            x: 30, y: 100,
            text: 'Standard font text',
            font: ZplFont.a,
            fontHeight: 20,
          ),
        ];
        
        return ZplPreview(generator: ZplGenerator(commands));
      },
    );
  }
}
```

### Convert Images to ZPL Graphics

Transform any image (PNG, JPEG, GIF) into ZPL graphics that can be embedded directly in your labels:

#### Basic Image Conversion

```dart
import 'dart:io';

// Load your image
final imageFile = File('assets/images/company_logo.png');
final imageBytes = await imageFile.readAsBytes();

// Convert to ZPL graphics
final zplGraphics = await LabelaryService.convertImageToGraphic(
  imageBytes,
  'logo.png',
  outputFormat: LabelaryGraphicOutputFormat.zpl,
);

print('ZPL Graphics Commands: $zplGraphics');
// Outputs: ~DG commands that define the image in ZPL
```

#### Using Images in Labels

```dart
// Method 1: Direct image embedding
final commands = [
  const ZplConfiguration(printWidth: 406, labelLength: 609),
  
  ZplImage(
    x: 20, y: 20,
    image: imageBytes,
    graphicName: 'LOGO.GRF', // Name for the graphic in ZPL
  ),
  
  const ZplText(
    x: 150, y: 80,
    text: 'Company Name',
    fontHeight: 25,
  ),
];

// Method 2: Pre-convert and store in printer memory
final graphicCommands = await LabelaryService.convertImageToGraphic(
  imageBytes,
  'logo.png',
  graphicName: 'LOGO',
);

// Send to printer once for reuse
await sendToPrinter(graphicCommands);

// Then reference in any label
final labelWithLogo = ZplGenerator([
  const ZplConfiguration(printWidth: 406, labelLength: 609),
  const ZplText(x: 20, y: 20, text: '^XGLOGO.GRF,1,1^FS'), // Reference stored graphic
]);
```

#### Advanced Image Features

```dart
// Convert with specific options
final zplGraphics = await LabelaryService.convertImageToGraphic(
  imageBytes,
  'photo.jpg',
  outputFormat: LabelaryGraphicOutputFormat.zpl,
  blackThreshold: 128, // Adjust for better contrast
  graphicName: 'PHOTO', // Custom name
);

// Multiple images in one label
final commands = [
  const ZplConfiguration(printWidth: 812, labelLength: 1218), // 4x6 inch
  
  // Company logo
  ZplImage(x: 50, y: 50, image: logoBytes, graphicName: 'LOGO.GRF'),
  
  // Product photo
  ZplImage(x: 300, y: 50, image: productBytes, graphicName: 'PRODUCT.GRF'),
  
  // QR code (generated separately)
  ZplImage(x: 600, y: 50, image: qrBytes, graphicName: 'QR.GRF'),
  
  const ZplText(x: 50, y: 300, text: 'Product Information', fontHeight: 30),
];
```

### Why These Features Matter

1. **🎨 Brand Consistency**: Use your exact corporate fonts and logos
2. **📱 Modern Design**: No limitations to basic printer fonts
3. **🏭 Enterprise Ready**: Upload assets once, use everywhere
4. **💾 Memory Efficient**: Store frequently used graphics in printer memory
5. **🚀 Performance**: Faster printing when assets are pre-loaded
6. **🌍 Multi-language**: Support for international fonts and characters

### 🏆 **Industry Advantages**

**No other Flutter ZPL package offers:**
- ✅ TTF font conversion and printer upload
- ✅ Automatic image-to-ZPL graphics conversion
- ✅ Live Flutter preview widget
- ✅ Complete Labelary API integration with all advanced features
- ✅ Memory management for printer assets
- ✅ Enterprise-grade font and image handling

**Perfect for:**
- 🏢 **Enterprise Applications**: Corporate branding requirements
- 🏪 **Retail Systems**: Product labels with custom fonts and logos
- 🏥 **Healthcare**: Patient wristbands with logos and custom formatting
- 📦 **Logistics**: Shipping labels with company branding
- 🏭 **Manufacturing**: Asset tags with specialized fonts and graphics

### Printer Memory Management

```dart
// Check available printer memory (implement with your printer SDK)
final availableMemory = await checkPrinterMemory();

// Clear old graphics if needed
if (availableMemory < requiredSpace) {
  await sendToPrinter('^XA^IDR:*.*^FS^XZ'); // Clear all graphics
}

// Upload optimized assets
await sendToPrinter(zplFontData);
await sendToPrinter(zplGraphicsData);
```

## Barcode Support

Supports all major barcode formats:

```dart
// Code 128
ZplBarcode(
  x: 10, y: 50,
  type: ZplBarcodeType.code128,
  data: 'ABC12345',
  height: 50,
)

// QR Code
ZplBarcode(
  x: 10, y: 120,
  type: ZplBarcodeType.qrCode,
  data: 'https://example.com',
  height: 100,
)

// UPC/EAN
ZplBarcode(
  x: 10, y: 250,
  type: ZplBarcodeType.upcA,
  data: '123456789012',
  height: 60,
)
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZPL Generator Demo',
      home: ProductLabelScreen(),
    );
  }
}

class ProductLabelScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Create a product label
    final commands = [
      const ZplConfiguration(
        printWidth: 406, // 2" wide
        labelLength: 609, // 3" tall
        printDensity: ZplPrintDensity.d8, // 203 DPI
      ),
      
      // Title
      const ZplText(
        x: 20, y: 20,
        text: 'PRODUCT LABEL',
        fontHeight: 25,
        fontWidth: 15,
      ),
      
      // Border
      const ZplBox(
        x: 10, y: 10,
        width: 386, height: 589,
        thickness: 3,
      ),
      
      // Product info in columns
      ZplColumn(
        x: 30, y: 60,
        spacing: 25,
        children: [
          ZplRow(
            spacing: 100,
            children: [
              const ZplText(text: 'SKU:', fontWeight: FontWeight.bold),
              const ZplText(text: 'ABC-12345'),
            ],
          ),
          ZplRow(
            spacing: 100,
            children: [
              const ZplText(text: 'Price:', fontWeight: FontWeight.bold),
              const ZplText(text: '\$29.99'),
            ],
          ),
        ],
      ),
      
      // Barcode
      const ZplBarcode(
        x: 50, y: 200,
        type: ZplBarcodeType.code128,
        data: 'ABC12345',
        height: 80,
        showText: true,
      ),
    ];

    final generator = ZplGenerator(commands);

    return Scaffold(
      appBar: AppBar(
        title: Text('Product Label'),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () async {
              // Generate and render label
              final response = await LabelaryService.renderFromGenerator(
                generator,
                outputFormat: LabelaryOutputFormat.pdf,
              );
              
              // Handle the rendered label (save, print, etc.)
              print('Label generated: ${response.data.length} bytes');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Live preview
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.all(16),
              child: ZplPreview(generator: generator),
            ),
            
            SizedBox(height: 20),
            
            // Generated ZPL
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    generator.build(),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Testing Labels

You can test your generated ZPL using:

1. **Online Labelary Viewer**: http://labelary.com/viewer.html
2. **Our ZplPreview widget** (recommended for Flutter apps)
3. **Physical Zebra printer**
4. **Labelary API directly**:

```bash
curl -X POST \
  'https://api.labelary.com/v1/printers/8dpmm/labels/4x6/0/' \
  -H 'Accept: image/png' \
  -d '^XA^FO20,20^A0N,25,25^FDHello World^FS^XZ'
```

## API Reference

### Core Classes

- **`ZplGenerator`**: Main class for building ZPL strings
- **`ZplConfiguration`**: Label setup and printer configuration
- **`ZplText`**: Text rendering with fonts and formatting
- **`ZplBarcode`**: Barcode generation (Code128, QR, UPC, etc.)
- **`ZplImage`**: Image embedding and positioning
- **`ZplBox`**: Rectangle and border drawing
- **`ZplRow`/`ZplColumn`**: Layout helpers

### Services

- **`LabelaryService`**: API integration for rendering and conversion
- **`ZplPreview`**: Flutter widget for live preview

### Enums

- **`ZplPrintDensity`**: Printer resolution (6, 8, 12, 24 DPI)
- **`ZplBarcodeType`**: Supported barcode formats
- **`LabelaryOutputFormat`**: Output formats (PNG, PDF, EPL, etc.)

For complete API documentation, see the [API reference](https://pub.dev/documentation/flutter_zpl_generator/).

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

- 📖 [Documentation](https://pub.dev/documentation/flutter_zpl_generator/)
- 🐛 [Issue Tracker](https://github.com/yourusername/flutter_zpl_generator/issues)
- 💬 [Discussions](https://github.com/yourusername/flutter_zpl_generator/discussions)

## Related Projects

- [Labelary API](https://labelary.com/) - Online ZPL viewer and API
- [ZPL Programming Guide](https://www.zebra.com/us/en/support-downloads/knowledge-articles/ait/zpl-programming-guide.html)
- [Zebra Printers](https://www.zebra.com/us/en/products/printers.html)