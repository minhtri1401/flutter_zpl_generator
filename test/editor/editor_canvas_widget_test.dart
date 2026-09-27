import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/zpl_label_editor.dart';

void main() {
  testWidgets('tap selects, drag moves, empty tap deselects', (tester) async {
    final c = EditorController(
      snapGrid: 0,
      guideThreshold: 0,
      document: const LabelDocument(
        config: ZplConfiguration(printWidth: 400, labelLength: 300),
        elements: [BoxElement(id: 'b', x: 50, y: 50, width: 100, height: 60)],
      ),
    );
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(width: 400, height: 300, child: ZplLabelCanvas(controller: c, showGrid: false, fitOnLayout: false)),
    ));

    final canvas = find.byKey(ZplLabelCanvas.gestureKey);
    final origin = tester.getTopLeft(canvas);

    await tester.tapAt(origin + const Offset(80, 70));
    await tester.pump();
    expect(c.selectedId, 'b');

    await tester.dragFrom(origin + const Offset(80, 70), const Offset(30, 20));
    await tester.pump();
    final e = c.selected as BoxElement;
    expect((e.x, e.y), (80, 70));

    await tester.tapAt(origin + const Offset(390, 290));
    await tester.pump();
    expect(c.selectedId, isNull);
  });

  testWidgets('empty-space drag pans the canvas', (tester) async {
    final transform = TransformationController();
    final c = EditorController(
      document: const LabelDocument(
        config: ZplConfiguration(printWidth: 400, labelLength: 300),
        elements: [BoxElement(id: 'b', x: 50, y: 50, width: 100, height: 60)],
      ),
    );
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 400,
        height: 300,
        child: ZplLabelCanvas(controller: c, showGrid: false, transformationController: transform, fitOnLayout: false),
      ),
    ));
    final origin = tester.getTopLeft(find.byKey(ZplLabelCanvas.gestureKey));
    await tester.dragFrom(origin + const Offset(390, 290), const Offset(-40, -30));
    await tester.pump();
    final t = transform.value.getTranslation();
    expect((t.x, t.y), (-40.0, -30.0));
    expect((c.document.elementById('b')!.x), 50);
  });

  testWidgets('fits the whole label into the viewport on first layout', (tester) async {
    final transform = TransformationController();
    final c = EditorController(
      document: const LabelDocument(config: ZplConfiguration(printWidth: 800, labelLength: 600)),
    );
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(width: 400, height: 400, child: ZplLabelCanvas(controller: c, transformationController: transform)),
      ),
    ));
    await tester.pumpAndSettle();
    final scale = transform.value.getMaxScaleOnAxis();
    expect(scale, closeTo(0.47, 0.001)); // min(400/800, 400/600) * 0.94
    final t = transform.value.getTranslation();
    expect(t.x, closeTo((400 - 800 * scale) / 2, 0.01));
    expect(t.y, closeTo((400 - 600 * scale) / 2, 0.01));
  });
}
