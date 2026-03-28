import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

class NativePreviewDemo extends StatefulWidget {
  const NativePreviewDemo({super.key});

  @override
  State<NativePreviewDemo> createState() => _NativePreviewDemoState();
}

class _NativePreviewDemoState extends State<NativePreviewDemo> {
  bool _showZpl = false;
  String? _zpl;
  late ZplGenerator _generator;

  static const _config = ZplConfiguration(
    printWidth: 812,
    labelLength: 600,
    printDensity: ZplPrintDensity.d8,
  );

  @override
  void initState() {
    super.initState();
    _generator = ZplGenerator(config: _config, commands: _buildCommands());
    _loadZpl();
  }

  Future<void> _loadZpl() async {
    final zpl = await _generator.build();
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
                  color: Theme.of(context).colorScheme.tertiaryContainer,
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  child: Text(
                    'Native Offline Preview (No API)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onTertiaryContainer,
                    ),
                  ),
                ),
                Container(
                  color: Colors.white,
                  constraints: const BoxConstraints(minHeight: 100),
                  child: SizedBox(
                    height: 400,
                    child: InteractiveViewer(
                      constrained: false,
                      minScale: 0.1,
                      maxScale: 3.0,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: ZplNativePreview(generator: _generator),
                      ),
                    ),
                  ),
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
                  const _FeatureRow(
                    text: '100% Offline CustomPainter rendering',
                  ),
                  const _FeatureRow(
                    text: 'Visualizations of primitives (Circles, Lines)',
                  ),
                  const _FeatureRow(text: 'Simulated Barcode rendering'),
                  const _FeatureRow(
                    text:
                        'Complex Layouts (Grid, Table, Column) natively mapped',
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

  List<ZplCommand> _buildCommands() {
    return [
      ZplBox(x: 10, y: 10, width: 792, height: 580, borderThickness: 4),
      ZplText(
        x: 0,
        y: 40,
        text: 'NATIVE PREVIEW DEMO',
        fontHeight: 40,
        fontWidth: 36,
        alignment: ZplAlignment.center,
      ),
      ZplSeparator(y: 100, thickness: 3),
      ZplGridRow(
        y: 120,
        children: [
          ZplGridCol(
            width: 6,
            child: ZplColumn(
              children: [
                ZplText(text: 'BILL TO:', fontHeight: 20),
                ZplText(text: 'ACME Corp', fontHeight: 30),
                ZplText(text: '123 Enterprise Way', fontHeight: 20),
                ZplText(text: 'Suite 100', fontHeight: 20),
              ],
            ),
          ),
          ZplGridCol(
            width: 6,
            child: ZplBarcode(
              x: 0,
              y: 0,
              type: ZplBarcodeType.code128,
              data: 'NT-PREVIEW',
              height: 60,
              printInterpretationLine: true,
            ),
          ),
        ],
      ),
      ZplSeparator(y: 280, thickness: 2),
      ZplGraphicCircle(x: 80, y: 400, diameter: 80, borderThickness: 3),
      ZplGraphicEllipse(
        x: 200,
        y: 400,
        width: 120,
        height: 80,
        borderThickness: 2,
      ),
      ZplGraphicDiagonalLine(
        x: 350,
        y: 400,
        width: 100,
        height: 60,
        borderThickness: 5,
        orientation: 'R',
      ),
      ZplGraphicDiagonalLine(
        x: 480,
        y: 400,
        width: 100,
        height: 60,
        borderThickness: 5,
        orientation: 'L',
      ),
      ZplText(
        x: 80,
        y: 500,
        text: 'Shapes rendered flawlessly offline',
        fontHeight: 26,
      ),
    ];
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;

  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
