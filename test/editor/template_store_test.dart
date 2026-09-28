import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/editor/storage/file_template_store.dart';
import 'package:flutter_zpl_generator/zpl_label_editor.dart';

LabelDocument _doc(int w) => LabelDocument(elements: [BoxElement(id: 'b', width: w)]);

void main() {
  test('memory store saves, lists newest first, loads, deletes', () async {
    final store = MemoryTemplateStore();
    final a = await store.save(_doc(10), name: 'A');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    final b = await store.save(_doc(20), name: 'B');
    expect((await store.list()).map((t) => t.name), ['B', 'A']);
    expect(((await store.load(a.id))!.elements.first as BoxElement).width, 10);
    final a2 = await store.save(_doc(11), id: a.id, name: 'A2');
    expect(a2.id, a.id);
    expect((await store.list()).length, 2);
    await store.delete(b.id);
    expect(await store.load(b.id), isNull);
  });

  test('file store round-trips through JSON files and skips junk', () async {
    final dir = await Directory.systemTemp.createTemp('zpl_tpl_');
    addTearDown(() => dir.delete(recursive: true));
    final store = FileTemplateStore(Directory('${dir.path}/nested'));
    expect(await store.list(), isEmpty);
    final info = await store.save(_doc(33), name: 'Shipping');
    await File('${store.directory.path}/junk.json').writeAsString('not json');
    final listed = await store.list();
    expect(listed.map((t) => t.name), ['Shipping']);
    expect(((await store.load(info.id))!.elements.first as BoxElement).width, 33);
    await store.delete(info.id);
    expect(await store.list(), isEmpty);
    expect(await store.load('missing'), isNull);
  });

  test('envelope decodes both envelopes and bare documents', () {
    final env = TemplateEnvelope.encodeString('X', DateTime(2026, 9, 28), _doc(5));
    final decoded = TemplateEnvelope.decodeString(env)!;
    expect(decoded.name, 'X');
    expect(decoded.updatedAt, DateTime(2026, 9, 28));
    expect(decoded.document.elements.length, 1);
    expect(TemplateEnvelope.decodeString('{"elements": []}')!.document.elements, isEmpty);
    expect(TemplateEnvelope.decodeString('nope'), isNull);
    expect(TemplateEnvelope.decodeString('{"a": 1}'), isNull);
  });

  test('controller tracks the current template', () {
    final c = EditorController();
    final info = TemplateInfo(id: 't', name: 'T', updatedAt: DateTime.now());
    c.addElement(const BoxElement(id: 'b'));
    c.loadTemplate(info, _doc(1));
    expect(c.currentTemplate, info);
    expect(c.canUndo, isFalse);
    c.markSaved(null);
    expect(c.currentTemplate, isNull);
  });
}
