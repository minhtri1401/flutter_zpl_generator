import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  runApp(const MyApp());
}

/// A simple data class to represent an item on the receipt.
class ReceiptItem {
  final int quantity;
  final String name;
  final double unitPrice;

  ReceiptItem({
    required this.quantity,
    required this.name,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZPL Generator Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ReceiptPreviewScreen(),
    );
  }
}

class ReceiptPreviewScreen extends StatefulWidget {
  const ReceiptPreviewScreen({super.key});

  @override
  State<ReceiptPreviewScreen> createState() => _ReceiptPreviewScreenState();
}

class _ReceiptPreviewScreenState extends State<ReceiptPreviewScreen> {
  // Receipt data matching the image
  final List<ReceiptItem> _items = [
    ReceiptItem(
      quantity: 1,
      name: 'Fuel Plastic Jug (10 gallons)',
      unitPrice: 34.00,
    ),
    ReceiptItem(quantity: 1, name: 'Gas Hose (5 feet)', unitPrice: 15.00),
    ReceiptItem(
      quantity: 100,
      name: 'Aluminum Screw (4 inches)',
      unitPrice: 0.87,
    ),
  ];

  final String _receiptNumber = '117 - 44332';
  final String _purchaseDate = 'December 8, 2023';
  final String _companyName = 'Big Machinery, LLC';
  final String _companyAddress = '3345, Diamond St, Orange City, ST 9987';
  final String _companyEmail = 'machinery@big.com';
  final String _customerName = 'Doe John';
  final String _customerAddress =
      'Address: 1111, Flemming St, Yellow City, AT 1121';

  List<ZplCommand> _generateReceiptCommands() {
    // Calculate totals
    final double subtotal = _items.fold(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    const double taxRate = 0.12;
    final double tax = subtotal * taxRate;
    final double total = subtotal + tax;

    final commands = <ZplCommand>[
      // Header - RECEIPT
      ZplText(
        x: 0,
        y: 30,
        text: 'RECEIPT',
        fontHeight: 50,
        fontWidth: 45,
        alignment: ZplAlignment.left,
      ),

      // Receipt number and date
      ZplText(
        x: 0,
        y: 100,
        text: 'Receipt number: $_receiptNumber',
        fontHeight: 20,
        fontWidth: 18,
        alignment: ZplAlignment.left,
      ),

      ZplText(
        x: 0,
        y: 130,
        text: 'Date of purchase: $_purchaseDate',
        fontHeight: 20,
        fontWidth: 18,
        alignment: ZplAlignment.left,
      ),

      // Company and Bill To section
      ZplGridRow(
        y: 200,
        children: [
          ZplGridCol(
            width: 6,
            child: ZplColumn(
              y: 0,
              children: [
                ZplText(
                  text: _companyName,
                  fontHeight: 25,
                  fontWidth: 22,
                  alignment: ZplAlignment.left,
                ),
                ZplText(
                  text: _companyAddress,
                  fontHeight: 18,
                  fontWidth: 16,
                  alignment: ZplAlignment.left,
                ),
                ZplText(
                  text: _companyEmail,
                  fontHeight: 18,
                  fontWidth: 16,
                  alignment: ZplAlignment.left,
                ),
              ],
            ),
          ),
          ZplGridCol(
            width: 6,
            child: ZplColumn(
              y: 0,
              children: [
                ZplText(
                  text: 'Bill By',
                  fontHeight: 25,
                  fontWidth: 22,
                  alignment: ZplAlignment.left,
                ),
                ZplText(
                  text: _customerName,
                  fontHeight: 18,
                  fontWidth: 16,
                  alignment: ZplAlignment.left,
                ),
                ZplText(
                  text: _customerAddress,
                  fontHeight: 18,
                  fontWidth: 16,
                  alignment: ZplAlignment.left,
                ),
              ],
            ),
          ),
        ],
      ),

      // Items table
      ZplTable(
        y: 360,
        columnWidths: [6, 2, 2, 2], // 12-column grid
        borderThickness: 2,
        cellPadding: 6,
        headers: [
          ZplTableHeader(
            'Item',
            alignment: ZplAlignment.left,
            fontHeight: 22,
            fontWidth: 20,
          ),
          ZplTableHeader(
            'Quantity',
            alignment: ZplAlignment.center,
            fontHeight: 22,
            fontWidth: 20,
          ),
          ZplTableHeader(
            'Unit Price',
            alignment: ZplAlignment.center,
            fontHeight: 22,
            fontWidth: 20,
          ),
          ZplTableHeader(
            'Total',
            alignment: ZplAlignment.center,
            fontHeight: 22,
            fontWidth: 20,
          ),
        ],
        data: _items
            .map(
              (item) => [
                item.name,
                item.quantity.toString().padLeft(2, '0'),
                '\$${item.unitPrice.toStringAsFixed(2)}',
                '\$${item.totalPrice.toStringAsFixed(2)}',
              ],
            )
            .toList(),
        dataFontHeight: 18,
        dataFontWidth: 16,
      ),

      // Subtotal
      ZplText(
        x: 50,
        y: 580,
        text: 'Subtotal: \$${subtotal.toStringAsFixed(2)}',
        fontHeight: 22,
        fontWidth: 20,
        alignment: ZplAlignment.left,
      ),

      // Additional Charges section
      ZplText(
        x: 50,
        y: 620,
        text: 'Additional Charges',
        fontHeight: 22,
        fontWidth: 20,
        alignment: ZplAlignment.left,
      ),

      ZplText(
        x: 50,
        y: 650,
        text:
            'Tax (${(taxRate * 100).toStringAsFixed(0)}%): \$${tax.toStringAsFixed(2)}',
        fontHeight: 20,
        fontWidth: 18,
        alignment: ZplAlignment.left,
      ),

      // Final Total
      ZplText(
        x: 50,
        y: 700,
        text: 'Total: \$${total.toStringAsFixed(2)}',
        fontHeight: 26,
        fontWidth: 24,
        alignment: ZplAlignment.left,
      ),
    ];

    return commands;
  }

  @override
  Widget build(BuildContext context) {
    final generator = ZplGenerator(
      config: const ZplConfiguration(
        printWidth: 576, // 2.25 inches at 203 dpi
        labelLength: 1200,
        printDensity: ZplPrintDensity.d8,
      ),
      commands: _generateReceiptCommands(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Big Machinery Receipt')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'Big Machinery Receipt Preview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ZplPreview(generator: generator),
              ),
              const SizedBox(height: 20),
              // Summary information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receipt #$_receiptNumber',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text('Date: $_purchaseDate'),
                      Text('Customer: $_customerName'),
                      const SizedBox(height: 8),
                      Text('Items: ${_items.length}'),
                      Text(
                        'Subtotal: \$${_items.fold(0.0, (sum, item) => sum + item.totalPrice).toStringAsFixed(2)}',
                      ),
                      Text(
                        'Total: \$${(_items.fold(0.0, (sum, item) => sum + item.totalPrice) * 1.12).toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
