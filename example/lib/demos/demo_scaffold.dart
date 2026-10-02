import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import '../printing/send_to_printer.dart';

/// Reusable scaffold for each demo tab.
/// Shows: Features + ZPL toggle -> Online preview -> Native preview.
class DemoScaffold extends StatefulWidget {
  final String title;
  final ZplGenerator generator;
  final List<String> features;

  const DemoScaffold({
    super.key,
    required this.title,
    required this.generator,
    required this.features,
  });

  @override
  State<DemoScaffold> createState() => _DemoScaffoldState();
}

class _DemoScaffoldState extends State<DemoScaffold> {
  bool _showZpl = false;
  String? _zpl;
  bool _sending = false;

  /// Last printer IP, shared across demo tabs.
  static String _lastHost = '';

  Future<void> _sendToPrinter() async {
    final zpl = _zpl;
    if (zpl == null) return;
    final controller = TextEditingController(text: _lastHost);
    final host = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send to printer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Printer IP address',
                hintText: '192.168.1.50',
              ),
              onSubmitted: (v) => Navigator.pop(context, v.trim()),
            ),
            const SizedBox(height: 12),
            const Text(
              'Sends this label over Wi-Fi (port 9100) with flutter_zpl_printer. '
              'It also supports Bluetooth LE and USB.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Print'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (host == null || host.isEmpty || !mounted) return;
    _lastHost = host;

    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sendZplToPrinter(host, zpl);
      messenger.showSnackBar(SnackBar(content: Text('Sent to $host')));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not print: $e')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadZpl();
  }

  @override
  void didUpdateWidget(covariant DemoScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.generator != oldWidget.generator) {
      _loadZpl();
    }
  }

  Future<void> _loadZpl() async {
    final zpl = await widget.generator.build();
    if (mounted) setState(() => _zpl = zpl);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Features used
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Features demonstrated',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...widget.features.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              f,
                              style: const TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (printingSupported) ...[
            FilledButton.icon(
              onPressed: _zpl == null || _sending ? null : _sendToPrinter,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.print),
              label: const Text('Send to printer'),
            ),
            const SizedBox(height: 8),
          ],

          // ZPL code toggle
          FilledButton.tonal(
            onPressed: () => setState(() => _showZpl = !_showZpl),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_showZpl ? Icons.visibility_off : Icons.code),
                const SizedBox(width: 8),
                Text(_showZpl ? 'Hide ZPL Code' : 'Show ZPL Code'),
              ],
            ),
          ),
          if (_showZpl && _zpl != null) ...[
            const SizedBox(height: 8),
            Card(
              color: Colors.grey.shade900,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SelectableText(
                      _zpl!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: Colors.greenAccent,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: const Icon(
                        Icons.copy,
                        size: 18,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _zpl!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ZPL copied to clipboard'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Online preview (Labelary API)
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: colorScheme.primaryContainer,
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  child: Text(
                    'Online Preview (Labelary API)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  constraints: const BoxConstraints(minHeight: 100),
                  child: ZplPreview(generator: widget.generator),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Native offline preview
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: colorScheme.tertiaryContainer,
                  width: double.infinity,
                  child: Text(
                    'Native Offline Preview (No API)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  constraints: const BoxConstraints(minHeight: 100),
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: ZplNativePreview(generator: widget.generator),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
