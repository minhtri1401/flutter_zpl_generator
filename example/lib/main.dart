import 'package:flutter/material.dart';

import 'demos/text_demo.dart';
import 'demos/barcode_demo.dart';
import 'demos/graphics_demo.dart';
import 'demos/layout_demo.dart';
import 'demos/receipt_demo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZPL Generator Showcase',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const ShowcaseHome(),
    );
  }
}

class ShowcaseHome extends StatelessWidget {
  const ShowcaseHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ZPL Generator Showcase'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.text_fields), text: 'Text'),
              Tab(icon: Icon(Icons.qr_code), text: 'Barcodes'),
              Tab(icon: Icon(Icons.shape_line), text: 'Graphics'),
              Tab(icon: Icon(Icons.grid_view), text: 'Layouts'),
              Tab(icon: Icon(Icons.receipt_long), text: 'Receipt'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TextDemo(),
            BarcodeDemo(),
            GraphicsDemo(),
            LayoutDemo(),
            ReceiptDemo(),
          ],
        ),
      ),
    );
  }
}
