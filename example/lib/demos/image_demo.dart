import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'demo_scaffold.dart';

class ImageDemo extends StatefulWidget {
  const ImageDemo({super.key});

  @override
  State<ImageDemo> createState() => _ImageDemoState();
}

class _ImageDemoState extends State<ImageDemo> {
  Uint8List? _gradientBytes;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final byteData =
        await rootBundle.load('assets/images/orioninnovation_logo.jpeg');
    setState(() {
      _gradientBytes = byteData.buffer.asUint8List();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gradientBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final generator = ZplGenerator(
      config: const ZplConfiguration(
        printWidth: 812,
        labelLength: 1000,
        printDensity: ZplPrintDensity.d8,
      ),
      commands: [
        ZplText(
          x: 0,
          y: 20,
          text: 'IMAGE DITHERING DEMO',
          fontHeight: 30,
          fontWidth: 28,
          alignment: ZplAlignment.center,
        ),
        ZplSeparator(y: 60, thickness: 2),

        // Threshold
        ZplText(
            x: 20,
            y: 100,
            text: 'Threshold (hard clip):',
            fontHeight: 20,
            fontWidth: 16),
        ZplImage(
          x: 400,
          y: 90,
          targetWidth: 300,
          image: _gradientBytes!,
          graphicName: 'LOGO_THR',
          ditheringAlgorithm: ZplDitheringAlgorithm.threshold,
        ),

        // Floyd-Steinberg
        ZplText(
            x: 20,
            y: 380,
            text: 'Floyd-Steinberg:',
            fontHeight: 20,
            fontWidth: 16),
        ZplImage(
          x: 400,
          y: 370,
          targetWidth: 300,
          image: _gradientBytes!,
          graphicName: 'LOGO_FS',
          ditheringAlgorithm: ZplDitheringAlgorithm.floydSteinberg,
        ),

        // Atkinson
        ZplText(
            x: 20, y: 660, text: 'Atkinson:', fontHeight: 20, fontWidth: 16),
        ZplImage(
          x: 400,
          y: 650,
          targetWidth: 300,
          image: _gradientBytes!,
          graphicName: 'LOGO_ATK',
          ditheringAlgorithm: ZplDitheringAlgorithm.atkinson,
        ),
      ],
    );

    return DemoScaffold(
      title: 'Image Dithering Algorithms',
      generator: generator,
      features: const [
        'ZplImage - prints graphics via ~DG',
        'ZplDitheringAlgorithm.threshold - hard contrast clip',
        'ZplDitheringAlgorithm.floydSteinberg - standard error diffusion',
        'ZplDitheringAlgorithm.atkinson - high contrast error diffusion',
      ],
    );
  }
}
