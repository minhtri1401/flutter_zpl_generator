
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import '../model/label_document.dart';

/// Shows the generated ZPL with copy and optional Labelary verification.
class ZplExportDialog extends StatefulWidget {
  final LabelDocument document;

  const ZplExportDialog({super.key, required this.document});

  static Future<void> show(BuildContext context, LabelDocument document) {
    return showDialog(
      context: context,
      builder: (_) => ZplExportDialog(document: document),
    );
  }

  @override
  State<ZplExportDialog> createState() => _ZplExportDialogState();
}

class _ZplExportDialogState extends State<ZplExportDialog> {
  String? _zpl;
  Uint8List? _render;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.document.buildZpl().then((z) {
      if (mounted) setState(() => _zpl = z);
    }).catchError((Object e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final png = await LabelaryService.renderFromGeneratorSimple(
        widget.document.toGenerator(),
      );
      if (mounted) setState(() => _render = png);
    } catch (e) {
      if (mounted) setState(() => _error = 'Labelary: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final zpl = _zpl;
    return AlertDialog(
      title: const Text('ZPL export'),
      content: SizedBox(
        width: 640,
        height: 480,
        child: zpl == null
            ? Center(child: _error == null ? const CircularProgressIndicator() : Text(_error!))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(zpl, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    ),
                  ),
                  if (_render != null)
                    Expanded(child: Image.memory(_render!, fit: BoxFit.contain)),
                  if (_error != null)
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: zpl == null ? null : () => Clipboard.setData(ClipboardData(text: zpl)),
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: zpl == null || _busy ? null : _verify,
          child: Text(_busy ? 'Rendering…' : 'Verify with Labelary'),
        ),
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
