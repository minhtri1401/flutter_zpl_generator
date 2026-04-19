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
    final byteData = await rootBundle.load(
      'assets/images/orioninnovation_logo.jpeg',
    );
    setState(() {
      _gradientBytes = byteData.buffer.asUint8List();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_gradientBytes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // v2.0 pattern: explicit Download (control, pre-^XA) + Recall (format, in ^XA…^XZ).
    final downloads = <ZplImageDownload>[
      ZplImageDownload(
        targetWidth: 300,
        image: _gradientBytes!,
        graphicName: 'LOGO_THR',
        ditheringAlgorithm: ZplDitheringAlgorithm.threshold,
      ),
      ZplImageDownload(
        targetWidth: 300,
        image: _gradientBytes!,
        graphicName: 'LOGO_FS',
        ditheringAlgorithm: ZplDitheringAlgorithm.floydSteinberg,
      ),
      ZplImageDownload(
        targetWidth: 300,
        image: _gradientBytes!,
        graphicName: 'LOGO_ATK',
        ditheringAlgorithm: ZplDitheringAlgorithm.atkinson,
      ),
    ];

    final generator = ZplGenerator(
      config: const ZplConfiguration(
        printWidth: 812,
        labelLength: 1000,
        printDensity: ZplPrintDensity.d8,
      ),
      commands: [
        ...downloads,
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
          fontWidth: 16,
        ),
        const ZplImageRecall(x: 400, y: 90, graphicName: 'LOGO_THR'),

        // Floyd-Steinberg
        ZplText(
          x: 20,
          y: 380,
          text: 'Floyd-Steinberg:',
          fontHeight: 20,
          fontWidth: 16,
        ),
        const ZplImageRecall(x: 400, y: 370, graphicName: 'LOGO_FS'),

        // Atkinson
        ZplText(
          x: 20,
          y: 660,
          text: 'Atkinson:',
          fontHeight: 20,
          fontWidth: 16,
        ),
        const ZplImageRecall(x: 400, y: 650, graphicName: 'LOGO_ATK'),
      ],
    );

    return DemoScaffold(
      title: 'Image Dithering Algorithms',
      generator: generator,
      features: const [
        'ZplImageDownload + ZplImageRecall - v2.0 Link-OS-safe image flow',
        'ZplDitheringAlgorithm.threshold - hard contrast clip',
        'ZplDitheringAlgorithm.floydSteinberg - standard error diffusion',
        'ZplDitheringAlgorithm.atkinson - high contrast error diffusion',
      ],
    );
  }
}
