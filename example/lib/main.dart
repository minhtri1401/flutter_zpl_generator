import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZPL Generator Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyLabelScreen(),
    );
  }
}

class MyLabelScreen extends StatelessWidget {
  const MyLabelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Define the label commands just like before
    final commands = [
      const ZplConfiguration(
        printWidth: 576, // 2.25 inches at 203 dpi
        labelLength: 1200,
        printDensity: ZplPrintDensity.d8,
      ),
      // ZplColumn(
      //   x: 0,
      //   y: 30,

      //   alignment: ZplAlignment.center,
      //   children: [
      //     ZplText(text: 'SHOP NAME', fontHeight: 40, fontWidth: 30),
      //     ZplText(
      //       text: 'Address: Lorem Ipsum, 23-10',
      //       fontHeight: 20,
      //       fontWidth: 15,
      //     ),
      //     ZplText(text: 'Telp. 11223344', fontHeight: 20, fontWidth: 15),
      //     ZplText(
      //       text: '*********************************',
      //       fontHeight: 20,
      //       fontWidth: 15,
      //     ),
      //     ZplText(text: 'CASH RECEIPT', fontHeight: 25, fontWidth: 20),
      //     ZplText(
      //       text: '*********************************',
      //       fontHeight: 20,
      //       fontWidth: 15,
      //     ),
      //   ],
      // ),

      // // Add a decorative separator
      // ZplSeparator(
      //   y: 250,
      //   type: ZplSeparatorType.character,
      //   character: '*',
      //   paddingLeft: 20,
      //   paddingRight: 20,
      //   fontHeight: 15,
      //   fontWidth: 12,
      // ),

      // ZplText(
      //   x: 30,
      //   y: 280,
      //   text: 'Description',
      //   fontHeight: 25,
      //   fontWidth: 20,
      // ),
      // ZplText(
      //   y: 280,
      //   text: 'Price',
      //   fontHeight: 25,
      //   fontWidth: 20,
      //   paddingRight: 20,
      //   alignment: ZplAlignment.right,
      // ),
      // // Item rows with left-aligned descriptions and right-aligned prices
      // ZplText(x: 30, y: 320, text: 'Lorem', fontHeight: 25, fontWidth: 20),
      // ZplText(
      //   y: 320,
      //   text: '1.1',
      //   fontHeight: 25,
      //   fontWidth: 20,
      //   paddingRight: 20,
      //   alignment: ZplAlignment.right,
      // ),

      // ZplText(x: 30, y: 350, text: 'Ipsum', fontHeight: 25, fontWidth: 20),
      // ZplText(
      //   y: 350,
      //   text: '2.2',
      //   fontHeight: 25,
      //   fontWidth: 20,
      //   paddingRight: 20,
      //   alignment: ZplAlignment.right,
      // ),

      // ZplText(
      //   x: 30,
      //   y: 380,
      //   text: 'Dolor sit amet',
      //   fontHeight: 25,
      //   fontWidth: 20,
      // ),
      // ZplText(
      //   y: 380,
      //   text: '3.3',
      //   fontHeight: 25,
      //   fontWidth: 20,
      //   paddingRight: 20,
      //   alignment: ZplAlignment.right,
      // ),

      // ZplText(
      //   x: 30,
      //   y: 410,
      //   text: 'Consectetur',
      //   fontHeight: 25,
      //   fontWidth: 20,
      // ),
      // ZplText(
      //   y: 410,
      //   text: '4.4',
      //   fontHeight: 25,
      //   fontWidth: 20,
      //   paddingRight: 20,
      //   alignment: ZplAlignment.right,
      // ),

      // ZplText(
      //   x: 30,
      //   y: 440,
      //   text: 'Adipiscing elit',
      //   fontHeight: 25,
      //   fontWidth: 20,
      // ),
      // ZplText(
      //   y: 440,
      //   text: '5.5',
      //   fontHeight: 25,
      //   fontWidth: 20,
      //   paddingRight: 20,
      //   alignment: ZplAlignment.right,
      // ),
      // ZplText(
      //   x: 30,
      //   y: 480,
      //   text: '*********************************',
      //   fontHeight: 20,
      //   fontWidth: 15,
      // ),
      // // Total section with right-aligned amounts
      // ZplText(x: 30, y: 510, text: 'Total', fontHeight: 35, fontWidth: 25),
      // ZplText(
      //   y: 510,
      //   text: '16.5',
      //   fontHeight: 35,
      //   fontWidth: 25,
      //   paddingRight: 20,
      //   alignment: ZplAlignment.right,
      // ),

      // ZplText(x: 30, y: 550, text: 'Cash', fontHeight: 25, fontWidth: 20),
      // ZplText(
      //   y: 550,
      //   text: '20.0',
      //   fontHeight: 25,
      //   fontWidth: 20,
      //   paddingRight: 20,
      //   alignment: ZplAlignment.right,
      // ),

      // ZplText(x: 30, y: 580, text: 'Change', fontHeight: 25, fontWidth: 20),
      // ZplText(
      //   y: 580,
      //   text: '3.5',
      //   fontHeight: 25,
      //   fontWidth: 20,
      //   paddingRight: 20,
      //   alignment: ZplAlignment.right,
      // ),
      // ZplText(
      //   x: 30,
      //   y: 620,
      //   text: '*********************************',
      //   fontHeight: 20,
      //   fontWidth: 15,
      // ),
      // // Bank info section
      // ZplText(x: 30, y: 650, text: 'Bank card', fontHeight: 25, fontWidth: 20),
      // ZplText(
      //   y: 650,
      //   text: '--- --- --- 234',
      //   fontHeight: 25,
      //   fontWidth: 20,
      //   paddingRight: 20,
      //   alignment: ZplAlignment.right,
      // ),

      // ZplText(
      //   x: 30,
      //   y: 680,
      //   text: 'Approval Code',
      //   fontHeight: 25,
      //   fontWidth: 20,
      // ),
      // ZplText(
      //   y: 680,
      //   text: '#123456',
      //   fontHeight: 25,
      //   fontWidth: 20,
      //   paddingRight: 20,
      //   alignment: ZplAlignment.right,
      // ),

      // ZplText(
      //   x: 30,
      //   y: 720,
      //   text: '*********************************',
      //   fontHeight: 20,
      //   fontWidth: 15,
      // ),
      // // Add a separator before the grid example
      // ZplSeparator(
      //   y: 740,
      //   type: ZplSeparatorType.character,
      //   character: '=',
      //   paddingLeft: 20,
      //   paddingRight: 20,
      //   fontHeight: 15,
      //   fontWidth: 12,
      // ),

      // Example using the new ZplTable widget
      ZplTable(
        y: 30,
        columnWidths: [6, 2, 2, 2], // 12-column grid widths
        borderThickness: 1, // Reduced for better text visibility
        cellPadding: 3, // Reduced for tighter layout
        headers: [
          ZplTableHeader(
            'Item',
            alignment: ZplAlignment.left,
            fontHeight: 20,
            fontWidth: 15,
          ),
          ZplTableHeader(
            'Qty',
            alignment: ZplAlignment.center,
            fontHeight: 20,
            fontWidth: 15,
          ),
          ZplTableHeader(
            'Price',
            alignment: ZplAlignment.right,
            fontHeight: 20,
            fontWidth: 15,
          ),
          ZplTableHeader(
            'Total',
            alignment: ZplAlignment.right,
            fontHeight: 20,
            fontWidth: 15,
          ),
        ],
        data: [
          [
            'V-Neck T-Shirt with Extra Long Product Name',
            '1',
            '10.00',
            '10.00',
          ],
          ['Polo Shirt', '2', '25.50', '51.00'],
          [
            'Jeans with Premium Fabric and Special Features',
            '1',
            '40.00',
            '40.00',
          ],
        ],
        dataFontHeight: 18,
        dataFontWidth: 13,
      ),

      // Example of manual text wrapping
      // ZplText(
      //   x: 30,
      //   y: 890,
      //   text:
      //       'This is a very long text that demonstrates automatic text wrapping across multiple lines within the specified cell width.',
      //   fontHeight: 18,
      //   fontWidth: 13,
      //   maxLines: 3,
      //   lineSpacing: 2,
      //   alignment: ZplAlignment.left,
      // ),

      // Example using custom TTF font (if available)
      // Note: Uncomment and add Roboto-Regular.ttf to assets to test
      // ZplText(
      //   x: 30,
      //   y: 930,
      //   text: 'Custom Roboto Font Example',
      //   fontHeight: 24,
      //   fontWidth: 20,
      //   customFont: ZplFontAsset(
      //     assetPath: 'assets/fonts/Roboto-Regular.ttf',
      //     identifier: 'A',
      //     displayName: 'Roboto Regular',
      //   ),
      // ),

      // Center-aligned thank you and barcode
      // ZplColumn(
      //   x: 0,
      //   y: 950,
      //   alignment: ZplAlignment.center,
      //   children: [
      //     ZplText(text: 'THANK YOU!', fontHeight: 30, fontWidth: 25),
      //     ZplBarcode(
      //       x: 0, // Will be repositioned by column alignment
      //       y: 50, // Relative to column
      //       height: 80,
      //       data: '1234567890',
      //       type: ZplBarcodeType.code128,
      //     ),
      //   ],
      // ),
    ];

    final generator = ZplGenerator(commands);

    // 2. Use the ZplPreview widget to display the rendered label
    return Scaffold(
      appBar: AppBar(title: const Text('Label Preview')),
      body: Center(
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
          // The widget handles everything automatically!
          child: ZplPreview(generator: generator),
        ),
      ),
    );
  }
}
