import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'package:flutter_zpl_generator/zpl_label_editor.dart';

/// Launcher tab: the editor itself opens as a full-screen route so canvas
/// drags never compete with the showcase's tab swipe.
class EditorDemo extends StatelessWidget {
  const EditorDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        icon: const Icon(Icons.design_services),
        label: const Text('Open label editor'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => const EditorPage(),
          ),
        ),
      ),
    );
  }
}

/// Full-screen editor page with a sample shipping label.
class EditorPage extends StatefulWidget {
  const EditorPage({super.key});

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  late final EditorController _controller = EditorController(
    document: LabelDocument(
      config: const ZplConfiguration(printWidth: 812, labelLength: 1218),
      elements: [
        const BoxElement(id: 'frame', x: 16, y: 16, width: 780, height: 1186, borderThickness: 3),
        const TextElement(id: 'title', x: 40, y: 40, text: 'SHIP TO', fontHeight: 50, fontWidth: 50),
        const TextElement(id: 'addr', x: 40, y: 110, text: 'Jane Doe\n1 Example St\nSaigon', fontHeight: 36, fontWidth: 36, maxLines: 3, maxWidth: 700),
        const LineElement(id: 'rule', x: 40, y: 260, length: 732, thickness: 3),
        const BarcodeElement(id: 'sscc', x: 60, y: 320, data: '00012345678901234567', height: 160, moduleWidth: 3),
        const BarcodeElement(id: 'qr', x: 560, y: 560, data: 'https://example.com', type: ZplBarcodeType.qrCode, magnification: 6),
      ],
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Uint8List?> _pickBundledLogo() async {
    final data = await rootBundle.load('assets/images/orioninnovation_logo.jpeg');
    return data.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Label editor')),
      body: ZplLabelEditor(controller: _controller, onPickImage: _pickBundledLogo),
    );
  }
}
