import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'demo_scaffold.dart';

class ReceiptItem {
  final int quantity;
  final String name;
  final double unitPrice;
  ReceiptItem(
      {required this.quantity, required this.name, required this.unitPrice});
  double get totalPrice => quantity * unitPrice;
}

class ReceiptDemo extends StatelessWidget {
  const ReceiptDemo({super.key});

  static const _config = ZplConfiguration(
    printWidth: 576,
    labelLength: 1200,
    printDensity: ZplPrintDensity.d8,
  );

  @override
  Widget build(BuildContext context) {
    final generator = ZplGenerator(config: _config, commands: _buildCommands());

    return DemoScaffold(
      title: 'Full Receipt Example',
      generator: generator,
      features: const [
        'Real-world receipt layout combining multiple features',
        'ZplGridRow - side-by-side company/billing info',
        'ZplTable - itemized product table with borders',
        'ZplSeparator - visual section dividers',
        'ZplText alignment - centered header, left body',
        'ZplColumn - vertical stacking in grid columns',
        'Calculated totals with tax',
      ],
    );
  }

  List<ZplCommand> _buildCommands() {
    final items = [
      ReceiptItem(
          quantity: 1, name: 'Fuel Plastic Jug (10 gal)', unitPrice: 34.00),
      ReceiptItem(quantity: 1, name: 'Gas Hose (5 feet)', unitPrice: 15.00),
      ReceiptItem(
          quantity: 100, name: 'Aluminum Screw (4 in)', unitPrice: 0.87),
    ];
    final subtotal = items.fold(0.0, (sum, i) => sum + i.totalPrice);
    const taxRate = 0.12;
    final tax = subtotal * taxRate;
    final total = subtotal + tax;

    return [
      // Header
      ZplText(
        x: 0,
        y: 30,
        text: 'RECEIPT',
        fontHeight: 50,
        fontWidth: 45,
        alignment: ZplAlignment.left,
      ),
      ZplText(
        x: 0,
        y: 100,
        text: 'Receipt number: 117 - 44332',
        fontHeight: 20,
        fontWidth: 18,
      ),
      ZplText(
        x: 0,
        y: 130,
        text: 'Date of purchase: December 8, 2023',
        fontHeight: 20,
        fontWidth: 18,
      ),

      // Company & Bill To
      ZplGridRow(
        y: 200,
        children: [
          ZplGridCol(
            width: 6,
            child: ZplColumn(
              children: [
                ZplText(
                    text: 'Big Machinery, LLC', fontHeight: 25, fontWidth: 22),
                ZplText(
                  text: '3345, Diamond St, Orange City, ST 9987',
                  fontHeight: 18,
                  fontWidth: 16,
                ),
                ZplText(
                    text: 'machinery@big.com', fontHeight: 18, fontWidth: 16),
              ],
            ),
          ),
          ZplGridCol(
            width: 6,
            child: ZplColumn(
              children: [
                ZplText(text: 'Bill To', fontHeight: 25, fontWidth: 22),
                ZplText(text: 'Doe John', fontHeight: 18, fontWidth: 16),
                ZplText(
                  text: '1111, Flemming St, Yellow City, AT 1121',
                  fontHeight: 18,
                  fontWidth: 16,
                ),
              ],
            ),
          ),
        ],
      ),

      // Items table
      ZplTable(
        y: 360,
        columnWidths: [6, 2, 2, 2],
        borderThickness: 2,
        cellPadding: 6,
        headers: [
          ZplTableHeader('Item',
              alignment: ZplAlignment.left, fontHeight: 22, fontWidth: 20),
          ZplTableHeader('Qty',
              alignment: ZplAlignment.center, fontHeight: 22, fontWidth: 20),
          ZplTableHeader('Unit',
              alignment: ZplAlignment.center, fontHeight: 22, fontWidth: 20),
          ZplTableHeader('Total',
              alignment: ZplAlignment.center, fontHeight: 22, fontWidth: 20),
        ],
        data: items
            .map((item) => [
                  item.name,
                  item.quantity.toString().padLeft(2, '0'),
                  '\$${item.unitPrice.toStringAsFixed(2)}',
                  '\$${item.totalPrice.toStringAsFixed(2)}',
                ])
            .toList(),
        dataFontHeight: 18,
        dataFontWidth: 16,
      ),

      // Totals
      ZplText(
        x: 50,
        y: 580,
        text: 'Subtotal: \$${subtotal.toStringAsFixed(2)}',
        fontHeight: 22,
        fontWidth: 20,
      ),
      ZplText(
        x: 50,
        y: 620,
        text: 'Additional Charges',
        fontHeight: 22,
        fontWidth: 20,
      ),
      ZplText(
        x: 50,
        y: 650,
        text: 'Tax (12%): \$${tax.toStringAsFixed(2)}',
        fontHeight: 20,
        fontWidth: 18,
      ),
      ZplSeparator(y: 685, thickness: 2, paddingLeft: 50, paddingRight: 50),
      ZplText(
        x: 50,
        y: 710,
        text: 'Total: \$${total.toStringAsFixed(2)}',
        fontHeight: 26,
        fontWidth: 24,
      ),

      // Footer with QR code
      ZplSeparator(y: 760, thickness: 1),
      ZplText(
        x: 0,
        y: 785,
        text: 'Scan for digital receipt:',
        fontHeight: 18,
        fontWidth: 14,
        alignment: ZplAlignment.center,
      ),
      ZplBarcode(
        x: 0,
        y: 815,
        data: 'https://receipt.example.com/117-44332',
        type: ZplBarcodeType.qrCode,
        height: 120,
        alignment: ZplAlignment.center,
      ),
      ZplText(
        x: 0,
        y: 960,
        text: 'Thank you for your business!',
        fontHeight: 22,
        fontWidth: 18,
        alignment: ZplAlignment.center,
      ),
    ];
  }
}
