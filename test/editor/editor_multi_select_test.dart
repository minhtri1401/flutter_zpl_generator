import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/zpl_label_editor.dart';

LabelDocument _doc() => const LabelDocument(
      config: ZplConfiguration(printWidth: 800, labelLength: 600),
      elements: [
        BoxElement(id: 'a', x: 100, y: 100, width: 100, height: 50),
        BoxElement(id: 'b', x: 300, y: 200, width: 50, height: 50),
        BoxElement(id: 'c', x: 600, y: 400, width: 80, height: 40),
      ],
    );

EditorController _c() => EditorController(document: _doc(), snapGrid: 0, guideThreshold: 0);

Map<String, (int, int)> _pos(EditorController c) =>
    {for (final e in c.document.elements) e.id: (e.x, e.y)};

void main() {
  group('selection set', () {
    test('toggle, select all, select in rect, primary is last picked', () {
      final c = _c();
      c.toggleSelect('a');
      c.toggleSelect('b');
      expect(c.selectedIds, ['a', 'b']);
      expect(c.selectedId, 'b');
      expect(c.hasMultipleSelected, isTrue);
      expect(c.selectionBounds, const Rect.fromLTRB(100, 100, 350, 250));
      c.toggleSelect('a');
      expect(c.selectedIds, ['b']);
      c.selectAll();
      expect(c.selectedIds.length, 3);
      c.selectInRect(const Rect.fromLTWH(0, 0, 320, 220));
      expect(c.selectedIds, ['a', 'b']);
      c.selectInRect(const Rect.fromLTWH(590, 390, 20, 20), additive: true);
      expect(c.selectedIds, ['a', 'b', 'c']);
      c.select(null);
      expect(c.selectedIds, isEmpty);
    });

    test('marquee selects what it covers', () {
      final c = _c();
      c.beginMarquee(const Offset(50, 50));
      c.updateMarquee(const Offset(320, 220));
      expect(c.marquee, const Rect.fromLTRB(50, 50, 320, 220));
      c.endMarquee();
      expect(c.selectedIds, ['a', 'b']);
      expect(c.marquee, isNull);
    });
  });

  group('group operations', () {
    test('drag moves every selected element together and clamps as a group', () {
      final c = _c();
      c.toggleSelect('a');
      c.toggleSelect('b');
      expect(c.beginDrag(const Offset(310, 210)), isTrue);
      expect(c.selectedIds, ['a', 'b']); // dragging a selected element keeps the set
      c.updateDrag(const Offset(320, 230));
      c.endDrag();
      expect(_pos(c)['a'], (110, 120));
      expect(_pos(c)['b'], (310, 220));

      c.beginDrag(const Offset(320, 230));
      c.updateDrag(const Offset(-1000, -1000));
      c.endDrag();
      expect(_pos(c)['a'], (0, 0));
      expect(_pos(c)['b'], (200, 100));
    });

    test('dragging an unselected element replaces or extends the selection', () {
      final c = _c()..select('a');
      c.beginDrag(const Offset(310, 210));
      expect(c.selectedIds, ['b']);
      c.endDrag();
      c.beginDrag(const Offset(110, 110), additive: true);
      expect(c.selectedIds, ['b', 'a']);
      c.endDrag();
      expect(c.hitTestHandle(const Offset(100, 100), 12), isNull); // no handles for groups
    });

    test('delete, duplicate, nudge and z-order apply to all', () {
      final c = _c();
      c.toggleSelect('a');
      c.toggleSelect('c');
      c.nudgeSelected(5, 0);
      expect((_pos(c)['a'], _pos(c)['c']), ((105, 100), (605, 400)));
      c.bringForward();
      expect(c.document.elements.map((e) => e.id), ['b', 'a', 'c']);
      c.sendBackward();
      // Each selected element steps back once: a 1→0, then c 2→1.
      expect(c.document.elements.map((e) => e.id), ['a', 'c', 'b']);
      c.duplicateSelected();
      expect(c.document.elements.length, 5);
      expect(c.selectedIds.length, 2);
      expect(c.selectedIds.contains('a'), isFalse);
      c.removeSelected();
      expect(c.document.elements.length, 3);
      c.undo();
      expect(c.document.elements.length, 5);
    });
  });

  group('align and distribute', () {
    test('single element aligns to the label', () {
      final c = _c()..select('a');
      c.alignSelected(AlignOp.centerX);
      c.alignSelected(AlignOp.bottom);
      expect(_pos(c)['a'], (350, 550));
      c.alignSelected(AlignOp.right);
      c.alignSelected(AlignOp.top);
      expect(_pos(c)['a'], (700, 0));
    });

    test('several elements align to their union', () {
      final c = _c()..selectAll();
      c.alignSelected(AlignOp.left);
      expect(c.document.elements.map((e) => e.x), [100, 100, 100]);
      c.alignSelected(AlignOp.centerY);
      // union top 100..bottom 440 → centre 270
      expect(_pos(c)['a']!.$2, 245);
      expect(_pos(c)['b']!.$2, 245);
      expect(_pos(c)['c']!.$2, 250);
      c.undo();
      c.undo();
      expect(_pos(c)['a'], (100, 100));
    });

    test('distribute needs three and equalises gaps', () {
      final c = _c();
      c.toggleSelect('a');
      c.toggleSelect('b');
      expect(c.canDistribute, isFalse);
      c.alignSelected(AlignOp.distributeH);
      expect(_pos(c)['b'], (300, 200));
      c.toggleSelect('c');
      c.alignSelected(AlignOp.distributeH);
      // span 100..680 = 580, occupied 230 → gap 175: b.x = 200 + 175 = 375
      expect(_pos(c)['b']!.$1, 375);
      expect(_pos(c)['a']!.$1, 100);
      expect(_pos(c)['c']!.$1, 600);
      c.alignSelected(AlignOp.distributeV);
      // span 100..440 = 340, occupied 140 → gap 100: b.y = 150 + 100 = 250
      expect(_pos(c)['b']!.$2, 250);
    });
  });
}
