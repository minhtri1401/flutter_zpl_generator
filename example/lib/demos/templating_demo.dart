import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

class TemplatingDemo extends StatefulWidget {
  const TemplatingDemo({super.key});

  @override
  State<TemplatingDemo> createState() => _TemplatingDemoState();
}

class _TemplatingDemoState extends State<TemplatingDemo> {
  late ZplTemplate _template;
  bool _isTemplateReady = false;

  Uint8List? _previewBytes;
  bool _isLoadingPreview = false;

  // Example looping data to swap easily
  final List<Map<String, dynamic>> _mockDatabase = [
    {
      'name': 'John Doe',
      'address': '123 Fake Street',
      'sku': 'APP-001',
      'price': '45.00',
      'barcode': '11111111',
    },
    {
      'name': 'Jane Smith',
      'address': '456 Real Ave',
      'sku': 'MAC-002',
      'price': '999.00',
      'barcode': '22222222',
    },
    {
      'name': 'Bob Logger',
      'address': '789 Timber Rd',
      'sku': 'LUM-003',
      'price': '12.50',
      'barcode': '33333333',
    },
  ];

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _initTemplate();
  }

  Future<void> _initTemplate() async {
    // 1. We construct the heavy template generator once.
    final generator = ZplGenerator(
      config: const ZplConfiguration(
        printWidth: 406,
        labelLength: 203, // 2x1 inch
        printDensity: ZplPrintDensity.d8,
      ),
      commands: [
        ZplBox(x: 10, y: 10, width: 386, height: 183, borderThickness: 2),
        ZplText(x: 20, y: 20, text: 'SHIP TO: {{name}}', fontHeight: 22),
        ZplText(x: 20, y: 50, text: '{{address}}', fontHeight: 18),
        ZplSeparator(y: 80, thickness: 2),
        ZplText(
          x: 20,
          y: 100,
          text: 'Item: {{sku}}   \${{price}}',
          fontHeight: 20,
        ),
        ZplBarcode(
          x: 20,
          y: 130,
          height: 40,
          type: ZplBarcodeType.code128,
          data: '{{barcode}}',
        ),
      ],
    );

    _template = ZplTemplate(generator);

    // Compile fonts, imagery, and grid geometry ONCE globally
    await _template.init();

    setState(() {
      _isTemplateReady = true;
    });

    _generatePreview();
  }

  Future<void> _generatePreview() async {
    if (!_isTemplateReady) return;

    setState(() {
      _isLoadingPreview = true;
    });

    try {
      // 2. We instantly bind variables exactly linearly synchronously
      final zplString = _template.bindSync(_mockDatabase[_currentIndex]);

      // Note: Since we have the raw string, we call Labelary natively
      // instead of using 'ZplPreview(generator:)' to demonstrate the power.
      final bytes = await LabelaryService.renderZplSimple(
        zplString,
        width: 2,
        height: 1,
        density: LabelaryPrintDensity.d8,
      );

      setState(() {
        _previewBytes = bytes;
      });
    } catch (e) {
      debugPrint('Error fetching preview: \$e');
    } finally {
      setState(() {
        _isLoadingPreview = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  child: Text(
                    'Data Binding Engine',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 20.0,
                  ),
                  child: const Text(
                    'Using ZplTemplate, we initialize the layout once to cache raw string geometries, and then inject Maps synchronously. \n\nSwitch personas below to dynamically regenerate ZPL with zero AST evaluation overhead.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_mockDatabase.length, (index) {
                    final active = _currentIndex == index;
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: active
                            ? Colors.indigo
                            : Colors.grey[300],
                        foregroundColor: active ? Colors.white : Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _currentIndex = index;
                        });
                        _generatePreview();
                      },
                      child: Text(_mockDatabase[index]['name'].split(' ')[0]),
                    );
                  }),
                ),
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  height: 300,
                  color: Colors.white,
                  child: Center(
                    child: !_isTemplateReady || _isLoadingPreview
                        ? const CircularProgressIndicator()
                        : _previewBytes != null
                        ? Image.memory(_previewBytes!)
                        : const Text('Error loading preview'),
                  ),
                ),
                const SizedBox(height: 20),
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
                  ...[
                    'ZplTemplate - highly optimized caching engine',
                    'Asynchronous Template initialization (await init())',
                    'Synchronous map binding (bindSync())',
                    'Flat string replacement injection parsing',
                  ].map(
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
        ],
      ),
    );
  }
}
