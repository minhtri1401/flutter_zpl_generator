import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

/// Reusable scaffold for each demo tab.
/// Shows the rendered label via ZplPreview + raw ZPL toggle + feature list.
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rendered label image
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
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
        ],
      ),
    );
  }
}
