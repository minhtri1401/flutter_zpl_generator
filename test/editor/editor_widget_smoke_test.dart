import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/zpl_label_editor.dart';

void main() {
  testWidgets('toolbar adds, inspector edits, undo reverts', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final c = EditorController();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ZplLabelEditor(controller: c))));

    await tester.tap(find.byTooltip('Add Box'));
    await tester.pump();
    expect(c.selected, isA<BoxElement>());

    await tester.enterText(find.widgetWithText(TextField, 'Width'), '321');
    await tester.pump();
    expect((c.selected as BoxElement).width, 321);

    await tester.tap(find.byTooltip('Undo'));
    await tester.pump();
    expect((c.selected as BoxElement).width, 200);

    await tester.tap(find.byTooltip('Delete'));
    await tester.pump();
    expect(c.document.elements, isEmpty);
    expect(find.text('LABEL'), findsOneWidget);
  });

  testWidgets('typing in an inspector field does not trigger canvas shortcuts', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);

    final c = EditorController();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: ZplLabelEditor(controller: c))));
    await tester.tap(find.byTooltip('Add Box'));
    await tester.pump();
    final x = (c.selected as BoxElement).x;

    await tester.tap(find.widgetWithText(TextField, 'Width'));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(c.document.elements.length, 1);
    expect((c.selected as BoxElement).x, x);
  });
}
