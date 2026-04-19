# 101 Guide: Getting Started with flutter_zpl_generator

Welcome to **flutter_zpl_generator**! If you need to print standard thermal labels, receipts, or shipping tags from your Flutter application, you've come to the right place.

ZPL (Zebra Programming Language) is the industry standard for industrial label printers. However, writing raw ZPL code by hand is tedious, error-prone, and hard to maintain. This library solves that problem by providing a declarative, Flutter-like API to generate precise ZPL code. 

Let's get you set up and printing highly accurate labels in minutes!

## 1. Installation

Add the package to your Flutter project's `pubspec.yaml` file:

```yaml
dependencies:
  flutter_zpl_generator: ^latest_version
```

Then run:
```bash
fvm flutter pub get
```

## 2. The Core Concepts

Think of `flutter_zpl_generator` like a Flutter Widget tree, but tailored for printers. You construct a hierarchy of objects, and the engine transforms it into ZPL code.

There are three main components you handle in every script:

1. **`ZplConfiguration`**: Defines the physical boundaries of your label (width, length) and the resolution of the printer (DPI/dpmm). This is passed dynamically.
2. **`ZplCommand`**: The visual building blocks (e.g., `ZplText`, `ZplBarcode`, `ZplImage`, `ZplBox`).
3. **`ZplGenerator`**: The orchestrator that takes your configuration and your list of commands, and combines them into a valid, printable ZPL string.

## 3. Your First Label

Let's build a simple label with some text and a barcode.

```dart
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

Future<void> buildMyFirstLabel() async {
  // 1. Initialize the Generator
  final generator = ZplGenerator(
    // 2. Define your paper size and printer resolution
    config: const ZplConfiguration(
      printWidth: 406, // 2 inches at 203 DPI
      labelLength: 203, // 1 inch at 203 DPI
      printDensity: ZplPrintDensity.d8, 
    ),
    // 3. Add your visual commands
    commands: [
      // Print some text at X: 20, Y: 20
      const ZplText(
        x: 20, 
        y: 20, 
        text: 'Hello Zebra Printer!',
      ),
      
      // Print a Code-128 Barcode below it
      const ZplBarcode(
        x: 20, 
        y: 60, 
        height: 50, 
        data: 'A1B2C3D4',
        type: ZplBarcodeType.code128,
        printInterpretationLine: true, // Shows the numbers below the barcode
      ),
    ],
  );

  // 4. Generate the ZPL String!
  final zplString = await generator.build();
  
  print(zplString); 
  // You now have raw ZPL. Send this string to your printer via Bluetooth, TCP, or USB!
}
```

## 4. The Magic of Containers & Layouts

One of the biggest pain points in manual ZPL is math. If you want to place text on the right side of the label, you'd usually guess the X coordinate.

**We solved this.** You can use layout containers like `ZplGridRow` to automatically structure your UI just like HTML columns or Flutter Rows!

```dart
ZplGridRow(
  y: 150, // Starts at Y position 150
  children: [
    // The library uses a 12-column grid system.
    ZplGridCol(
      width: 6, // 50% of the screen width
      child: const ZplText(text: 'LEFT SIDE', alignment: ZplAlignment.left),
    ),
    ZplGridCol(
      width: 6, // The other 50%
      child: const ZplText(text: 'RIGHT SIDE', alignment: ZplAlignment.right),
    ),
  ],
)
```
No more manual calculation. The engine automatically looks at your `ZplConfiguration.printWidth` and spaces elements out flawlessly.

## 5. Live Previewing in Flutter

You don't need to waste a physical roll of thermal paper just to tune your design! 
You can preview exactly what your label will look like right inside your Flutter App UI:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

class LabelPreviewScreen extends StatelessWidget {
  final generator = ZplGenerator(
    config: const ZplConfiguration(printWidth: 406, labelLength: 203),
    commands: [
      const ZplText(x: 10, y: 10, text: 'Live Preview!'),
    ]
  );

  LabelPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Label Designer')),
      body: Center(
        child: ZplPreview(
          generator: generator, // Hot-reloads in real-time when properties change!
        ),
      ),
    );
  }
}
```

## Summary

You now know how to:
* Initialize a basic label using `ZplConfiguration` and `ZplGenerator`
* Render texts and barcodes using standard `ZplCommand` blocks
* Layout items automatically using `ZplGridRow` and `ZplAlignment`
* Utilize `ZplPreview` to debug your graphics visually without a printer

**Next Steps**: Check out the rich support for importing Custom Fonts (`ZplFontAsset`), generating Tables (`ZplTable`), drawing Graphics (`ZplBox`, `ZplGraphicCircle`), and native caching engines in the codebase.
