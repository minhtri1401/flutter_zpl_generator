import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/zpl_label_editor.dart';

void main() {
  final doc = LabelDocument(
    elements: const [
      TextElement(id: 't', text: 'Order {{orderNo}} for {{name}}'),
      BarcodeElement(id: 'b', data: '{{orderNo}}', height: 50),
      TextElement(id: 'u', text: 'no {{ spaced }} nor {{bad-name}}'),
      BoxElement(id: 'x'),
    ],
    sampleData: const {'orderNo': 'A-1', 'name': 'Jane'},
  );

  test('scan returns unique names in first-seen order', () {
    expect(doc.variables, ['orderNo', 'name']);
    expect(const LabelDocument().variables, isEmpty);
  });

  test('bound ZPL substitutes sample data and keeps unknown placeholders', () async {
    final zpl = await doc.buildBoundZpl();
    expect(zpl, contains('Order A-1 for Jane'));
    expect(zpl, contains('^FDA-1^FS'));
    final partial = await doc.buildBoundZpl({'name': 'Bob'});
    expect(partial, contains('Order {{orderNo}} for Bob'));
  });

  test('sample data survives JSON and copyWith', () {
    final restored = LabelDocument.fromJson(jsonDecode(jsonEncode(doc.toJson())) as Map<String, dynamic>);
    expect(restored.sampleData, {'orderNo': 'A-1', 'name': 'Jane'});
    expect(doc.withSample('name', 'Zed').sampleData['name'], 'Zed');
    expect(LabelDocument.fromJson({'elements': [], 'sampleData': {'k': 5}}).sampleData, {'k': '5'});
  });

  test('controller coalesces sample edits into one undo step', () {
    final c = EditorController(document: doc);
    c.setSampleValue('name', 'J');
    c.setSampleValue('name', 'Jo');
    c.undo();
    expect(c.document.sampleData['name'], 'Jane');
    expect(c.canUndo, isFalse);
  });
}
