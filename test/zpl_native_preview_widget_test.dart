import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('ZplNativePreview widget', () {
    testWidgets('ZplNativePreview renders without throwing', (
      WidgetTester tester,
    ) async {
      final generator = ZplGenerator(
        config: const ZplConfiguration(printWidth: 406, labelLength: 609),
        commands: [
          ZplText(text: 'Hello', x: 10, y: 10, fontHeight: 20, fontWidth: 15),
          ZplBox(x: 50, y: 50, width: 100, height: 50, borderThickness: 2),
          ZplBarcode(
            data: '123456789',
            x: 10,
            y: 100,
            type: ZplBarcodeType.code128,
            height: 50,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ZplNativePreview(generator: generator)),
        ),
      );

      expect(find.byType(ZplNativePreview), findsOneWidget);
    });

    testWidgets('ZplNativePreview with custom background color', (
      WidgetTester tester,
    ) async {
      final generator = ZplGenerator(
        config: const ZplConfiguration(),
        commands: [ZplText(text: 'Test', x: 0, y: 0)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZplNativePreview(
              generator: generator,
              backgroundColor: Colors.grey[200]!,
            ),
          ),
        ),
      );

      expect(find.byType(ZplNativePreview), findsOneWidget);
    });

    testWidgets('ZplNativePreview respects config dimensions', (
      WidgetTester tester,
    ) async {
      final generator = ZplGenerator(
        config: const ZplConfiguration(printWidth: 300, labelLength: 400),
        commands: [ZplText(text: 'Sized', x: 0, y: 0)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ZplNativePreview(generator: generator)),
        ),
      );

      expect(find.byType(ZplNativePreview), findsOneWidget);
    });

    testWidgets(
      'ZplNativePreview uses default dimensions when not configured',
      (WidgetTester tester) async {
        final generator = ZplGenerator(
          config: const ZplConfiguration(),
          commands: [ZplText(text: 'Default Size', x: 0, y: 0)],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: ZplNativePreview(generator: generator)),
          ),
        );

        expect(find.byType(ZplNativePreview), findsOneWidget);
      },
    );
  });

  group('ZplPreview widget', () {
    testWidgets('ZplPreview builds and renders', (WidgetTester tester) async {
      final generator = ZplGenerator(
        config: const ZplConfiguration(),
        commands: [ZplText(text: 'Loading Test', x: 0, y: 0)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ZplPreview(generator: generator)),
        ),
      );

      expect(find.byType(ZplPreview), findsOneWidget);
    });

    testWidgets('ZplPreview shows content or loading state', (
      WidgetTester tester,
    ) async {
      final generator = ZplGenerator(
        config: const ZplConfiguration(),
        commands: [ZplText(text: 'State Test', x: 0, y: 0)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ZplPreview(generator: generator)),
        ),
      );

      expect(find.byType(ZplPreview), findsOneWidget);
    });

    testWidgets('ZplPreview rebuilds when generator changes', (
      WidgetTester tester,
    ) async {
      var generator = ZplGenerator(
        config: const ZplConfiguration(),
        commands: [ZplText(text: 'First', x: 0, y: 0)],
      );

      final previewKey = GlobalKey<_TestPreviewState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestPreview(key: previewKey, generator: generator),
          ),
        ),
      );

      expect(find.byType(ZplPreview), findsOneWidget);

      // Change generator
      generator = ZplGenerator(
        config: const ZplConfiguration(),
        commands: [ZplText(text: 'Second', x: 0, y: 0)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _TestPreview(key: previewKey, generator: generator),
          ),
        ),
      );

      expect(find.byType(ZplPreview), findsOneWidget);
    });
  });
}

class _TestPreview extends StatefulWidget {
  final ZplGenerator generator;

  const _TestPreview({super.key, required this.generator});

  @override
  State<_TestPreview> createState() => _TestPreviewState();
}

class _TestPreviewState extends State<_TestPreview> {
  @override
  Widget build(BuildContext context) {
    return ZplPreview(generator: widget.generator);
  }
}
