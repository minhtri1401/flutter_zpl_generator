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

      ZplText(
        text: 'THANK YOU!',
        fontHeight: 30,
        fontWidth: 25,
        alignment: ZplAlignment.center,
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
