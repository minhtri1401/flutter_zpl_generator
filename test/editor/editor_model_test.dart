import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/zpl_label_editor.dart';

String normalizeZpl(String zpl) =>
    zpl.replaceAll(RegExp(r'\n\s*'), '\n').trim();

// Tiny valid 2x2 PNG so ZplImageInline can decode it.
final Uint8List _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAEklEQVR42mNk+M9Qz8DAwAAA'
  'DQADgqx4sQAAAABJRU5ErkJggg==',
);

LabelDocument _sample() => LabelDocument(
      config: const ZplConfiguration(printWidth: 812, labelLength: 1218),
      elements: [
        const TextElement(id: 't1', x: 10, y: 20, text: 'Hello', fontHeight: 40, fontWidth: 40),
        const BarcodeElement(id: 'b1', x: 10, y: 100, data: '12345', height: 80),
        const BoxElement(id: 'x1', x: 5, y: 5, width: 300, height: 200, borderThickness: 3),
        const CircleElement(id: 'c1', x: 400, y: 400, diameter: 90),
        const LineElement(id: 'l1', x: 0, y: 300, length: 500, thickness: 4),
        ImageElement(id: 'i1', x: 600, y: 600, image: _png, targetWidth: 50, targetHeight: 50),
      ],
    );

void main() {
  group('LabelDocument → ZPL', () {
    test('matches hand-built generator byte for byte', () async {
      final doc = _sample();
      final expected = ZplGenerator(
        config: doc.config,
        commands: [
          ZplText(x: 10, y: 20, text: 'Hello', fontHeight: 40, fontWidth: 40),
          ZplBarcode(x: 10, y: 100, data: '12345', height: 80, moduleWidth: 2),
          ZplBox(x: 5, y: 5, width: 300, height: 200, borderThickness: 3),
          const ZplGraphicCircle(x: 400, y: 400, diameter: 90, borderThickness: 2),
          ZplSeparator(x: 0, y: 300, length: 500, thickness: 4),
          ZplImageInline(x: 600, y: 600, image: _png, targetWidth: 50, targetHeight: 50),
        ],
      );
      expect(normalizeZpl(await doc.buildZpl()), normalizeZpl(await expected.build()));
    });

    test('element order equals emission order', () async {
      final doc = _sample().bringForward('t1');
      final zpl = await doc.buildZpl();
      expect(zpl.indexOf('^BC'), lessThan(zpl.indexOf('^FDHello')));
    });
  });

  group('JSON round trip', () {
    test('is lossless for all element types and config', () async {
      final doc = _sample();
      final restored = LabelDocument.fromJson(
        jsonDecode(jsonEncode(doc.toJson())) as Map<String, dynamic>,
      );
      expect(restored.elements.map((e) => e.id), doc.elements.map((e) => e.id));
      expect(restored.config.printWidth, 812);
      expect(restored.config.labelLength, 1218);
      expect(await restored.buildZpl(), await doc.buildZpl());
    });

    test('tolerates wrong-typed id/bool fields and unknown config enums', () {
      final doc = LabelDocument.fromJson({
        'config': {'printMode': 'bogus', 'printWidth': 400},
        'elements': [
          {'type': 'box', 'id': 7, 'reversePrint': 'yes'},
          {'type': 'text', 'id': 't', 'text': 12},
        ],
      });
      expect(doc.elements.length, 2);
      expect(doc.config.printMode, isNull);
      expect((doc.elements.first as BoxElement).reversePrint, isFalse);
      expect((doc.elements.last as TextElement).text, '');
    });

    test('skips unknown element types and bad ints', () {
      final doc = LabelDocument.fromJson({
        'version': 1,
        'config': {'printWidth': 406.0},
        'elements': [
          {'type': 'hologram', 'id': 'h'},
          {'type': 'box', 'id': 'ok', 'width': 10.4, 'height': 'nope'},
        ],
      });
      expect(doc.elements.length, 1);
      expect(doc.config.printWidth, 406);
      expect((doc.elements.first as BoxElement).width, 10);
      expect((doc.elements.first as BoxElement).height, 100);
    });
  });

  group('bounds and resize', () {
    const cfg = ZplConfiguration(printWidth: 812);

    test('box/circle/line/image bounds are explicit sizes', () {
      final doc = _sample();
      expect(doc.elementById('x1')!.bounds(cfg), const Rect.fromLTWH(5, 5, 300, 200));
      expect(doc.elementById('c1')!.bounds(cfg), const Rect.fromLTWH(400, 400, 90, 90));
      expect(doc.elementById('l1')!.bounds(cfg), const Rect.fromLTWH(0, 300, 500, 4));
      expect(doc.elementById('i1')!.bounds(cfg), const Rect.fromLTWH(600, 600, 50, 50));
    });

    test('text bounds use longest line advance and font height', () {
      const t = TextElement(id: 't', text: 'Hello\nHi', fontHeight: 40, fontWidth: 40, maxLines: 2, lineSpacing: 4);
      final b = t.bounds(cfg);
      expect(b.width, (5 * 40 * TextElement.avgCharAdvance).ceilToDouble());
      expect(b.height, 84);
      expect(t.copyWith(maxWidth: () => 90).bounds(cfg).width, 90);
    });

    test('rotated text swaps width and height', () {
      const t = TextElement(id: 't', text: 'Hello', fontHeight: 40, fontWidth: 40, orientation: ZplOrientation.rotated90);
      final b = t.bounds(cfg);
      expect(b.width, 40);
      expect(b.height, (5 * 40 * TextElement.avgCharAdvance).ceilToDouble());
    });

    test('rotated text/barcode resize keeps un-oriented metrics', () {
      const t = TextElement(id: 't', text: 'Hello', fontHeight: 40, fontWidth: 40, orientation: ZplOrientation.rotated90);
      final tb = t.bounds(cfg);
      final same = t.resizeTo(tb.width.round(), tb.height.round());
      expect((same.fontHeight, same.fontWidth), (40, 40));
      final taller = t.resizeTo(80, tb.height.round());
      expect(taller.fontHeight, 80);

      const b = BarcodeElement(id: 'b', data: '1', height: 80, orientation: ZplOrientation.rotated90);
      final bb = b.bounds(cfg);
      final sameB = b.resizeTo(bb.width.round(), bb.height.round());
      expect((sameB.height, sameB.moduleWidth), (80, 2));
    });

    test('alignment without wrap width is not emitted', () {
      const t = TextElement(id: 't', x: 100, text: 'Hi', alignment: ZplAlignment.center);
      expect(t.toCommand().alignment, isNull);
      expect(t.copyWith(maxWidth: () => 300).toCommand().alignment, ZplAlignment.center);
    });

    test('pdf417 has no interpretation line in bounds', () {
      const b = BarcodeElement(id: 'b', data: '1', height: 10, type: ZplBarcodeType.pdf417);
      expect(b.hasInterpretationLine, isFalse);
      expect(b.bounds(cfg).height, 10);
    });

    test('out-of-range JSON values are clamped before reaching commands', () async {
      final b = BarcodeElement.fromJson('b', {'data': '1', 'magnification': 99, 'moduleWidth': 0, 'height': -5});
      expect((b.toCommand().magnification, b.toCommand().moduleWidth, b.toCommand().height), (10, 1, 1));
      final l = LineElement.fromJson('l', {'length': 0, 'thickness': -1});
      final zpl = await LabelDocument(elements: [l, b]).buildZpl();
      expect(zpl, contains('^GB1,1'));
    });

    test('barcode bounds include interpretation line', () {
      const b = BarcodeElement(id: 'b', data: '123', height: 80);
      expect(b.bounds(cfg).height, 80 + BarcodeElement.interpretationLineHeight);
      expect(b.copyWith(printInterpretationLine: false).bounds(cfg).height, 80);
    });

    test('resize changes the right properties per type', () {
      final box = const BoxElement(id: 'x', width: 100, height: 50).resizeTo(150, 75);
      expect((box.width, box.height), (150, 75));

      final circle = const CircleElement(id: 'c', diameter: 100).resizeTo(60, 90);
      expect(circle.diameter, 60);

      final line = const LineElement(id: 'l', length: 100, thickness: 2, vertical: true).resizeTo(6, 300);
      expect((line.length, line.thickness), (300, 6));

      final text = const TextElement(id: 't', text: 'Hi', fontHeight: 20, fontWidth: 20).resizeTo(80, 40);
      expect(text.fontHeight, 40);

      final bc = const BarcodeElement(id: 'b', data: '1', height: 80, moduleWidth: 2);
      final grown = bc.resizeTo(bc.bounds(cfg).width.round() * 2, 120);
      expect(grown.moduleWidth, 4);
      expect(grown.height, 100);

      final qr = const BarcodeElement(id: 'q', data: '1', type: ZplBarcodeType.qrCode, magnification: 3);
      final qrGrown = qr.resizeTo(qr.bounds(cfg).width.round() * 2, 0);
      expect(qrGrown.magnification, 6);
    });

    test('moveTo keeps identity', () {
      final moved = _sample().update('t1', (e) => e.moveTo(99, 98));
      final t = moved.elementById('t1') as TextElement;
      expect((t.x, t.y, t.text), (99, 98, 'Hello'));
    });
  });

  group('document ops', () {
    test('add/remove/update/z-order', () {
      var doc = const LabelDocument();
      doc = doc.add(const BoxElement(id: 'a')).add(const BoxElement(id: 'b'));
      expect(doc.elements.map((e) => e.id), ['a', 'b']);
      doc = doc.sendBackward('b');
      expect(doc.elements.map((e) => e.id), ['b', 'a']);
      expect(doc.sendBackward('b').elements.map((e) => e.id), ['b', 'a']);
      doc = doc.remove('a');
      expect(doc.elements.length, 1);
      expect(doc.update('missing', (e) => e).elements.length, 1);
    });
  });

  group('error paths and edge cases', () {
    test('ImageElement fromJson handles invalid base64', () {
      final elem = ImageElement.fromJson('img1', {
        'image': 'not-valid-base64!!!',
        'targetWidth': 100,
        'targetHeight': 100,
      });
      expect(elem.image.length, 0); // empty bytes fallback
      expect(elem.targetWidth, 100);
    });

    test('resize clamping respects min/max bounds', () {
      // ImageElement clamps to 1-32000
      var img = ImageElement(id: 'i', image: _png, targetWidth: 50, targetHeight: 50);
      expect(img.resizeTo(0, 0).targetWidth, 1);
      expect(img.resizeTo(50000, 50000).targetWidth, 32000);

      // CircleElement clamps to 3-4095
      var circle = const CircleElement(id: 'c', diameter: 100);
      expect(circle.resizeTo(1, 1).diameter, 3);
      expect(circle.resizeTo(5000, 5000).diameter, 4095);

      // TextElement clamps font to 10-1000
      var text = const TextElement(id: 't', text: 'Hi', fontHeight: 30, fontWidth: 30);
      final resized = text.resizeTo(5, 5);
      expect(resized.fontHeight, greaterThanOrEqualTo(10));
      expect(resized.fontHeight, lessThanOrEqualTo(1000));
    });

    test('barcode bounds differs for 1D vs 2D types', () {
      const cfg = ZplConfiguration();
      final code128 = const BarcodeElement(id: 'b1', data: '123', type: ZplBarcodeType.code128, height: 80);
      final qr = const BarcodeElement(id: 'b2', data: '123', type: ZplBarcodeType.qrCode);

      // 1D includes interpretation line
      expect(code128.bounds(cfg).height, 80 + BarcodeElement.interpretationLineHeight);

      // 2D is square
      expect(qr.bounds(cfg).width, qr.bounds(cfg).height);
    });

    test('JSON fromJson handles missing/wrong typed fields per element', () {
      // TextElement with missing text defaults to empty
      final t = TextElement.fromJson('t', {'fontHeight': 40});
      expect(t.text, '');
      expect(t.fontHeight, 40);

      // BarcodeElement with wrong type for int field
      final b = BarcodeElement.fromJson('b', {'height': 'not-an-int', 'data': '123'});
      expect(b.height, 80); // default
      expect(b.data, '123');

      // LineElement with missing vertical
      final l = LineElement.fromJson('l', {});
      expect(l.vertical, false);
    });
  });
}
