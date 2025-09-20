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
        printWidth: 406, // 2 inches at 203 dpi
        labelLength: 203, // 1 inch at 203 dpi
        printDensity: ZplPrintDensity.d8,
      ),
      const ZplText(x: 20, y: 20, text: 'This is a preview!'),
      const ZplBarcode(x: 20, y: 60, height: 50, data: '12345'),
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
