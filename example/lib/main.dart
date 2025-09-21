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
      ZplColumn(
        x: 0,
        y: 30,
        children: [
          ZplText(
            text: 'SHOP NAME',
            fontHeight: 40,
            fontWidth: 30,
            alignment: ZplAlignment.center,
          ),
          ZplText(
            text: 'Address: Lorem Ipsum, 23-10',
            fontHeight: 20,
            fontWidth: 15,
          ),
          ZplText(text: 'Telp. 11223344', fontHeight: 20, fontWidth: 15),
          ZplText(
            text: '*********************************',
            fontHeight: 20,
            fontWidth: 15,
          ),
          ZplText(text: 'CASH RECEIPT', fontHeight: 25, fontWidth: 20),
          ZplText(
            text: '*********************************',
            fontHeight: 20,
            fontWidth: 15,
          ),
        ],
      ),
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
