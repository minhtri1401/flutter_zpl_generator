
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import '../editor_controller.dart';
import 'inspector_fields.dart';

/// Shows the generated ZPL with copy and optional Labelary verification.
/// When the label uses `{{placeholders}}`, one field per variable lets the
/// user enter sample data; the ZPL shown (and verified) is the bound output.
class ZplExportDialog extends StatefulWidget {
  final EditorController controller;

  const ZplExportDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, EditorController controller) {
    return showDialog(
      context: context,
      builder: (_) => ZplExportDialog(controller: controller),
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
    widget.controller.addListener(_rebuild);
    _rebuild();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    widget.controller.document
        .buildBoundZpl()
        .then((z) {
          if (mounted) setState(() => _zpl = z);
        })
        .catchError((Object e) {
          if (mounted) setState(() => _error = e.toString());
        });
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final zpl = _zpl;
      if (zpl == null) return;
      final png = await LabelaryService.renderZplSimple(zpl);
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
    final doc = widget.controller.document;
    final variables = doc.variables;
    return AlertDialog(
      title: const Text('ZPL export'),
      content: SizedBox(
        width: 640,
        height: 520,
        child: zpl == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Text(_error!),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  if (variables.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final v in variables)
                          SizedBox(
                            width: 180,
                            child: StringField(
                              label: v,
                              value: doc.sampleData[v] ?? '',
                              onChanged: (val) =>
                                  widget.controller.setSampleValue(v, val),
                            ),
                          ),
                      ],
                    ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: SelectableText(
                        zpl,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  if (_render != null)
                    Expanded(
                      child: Image.memory(_render!, fit: BoxFit.contain),
                    ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: zpl == null
              ? null
              : () => Clipboard.setData(ClipboardData(text: zpl)),
          child: const Text('Copy'),
        ),
        TextButton(
          onPressed: zpl == null || _busy ? null : _verify,
          child: Text(_busy ? 'Rendering…' : 'Verify with Labelary'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
