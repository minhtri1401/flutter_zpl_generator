
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/zpl_label_editor.dart';

LabelDocument _doc() => const LabelDocument(
      config: ZplConfiguration(printWidth: 800, labelLength: 600),
      elements: [
        BoxElement(id: 'back', x: 100, y: 100, width: 200, height: 100),
        BoxElement(id: 'front', x: 150, y: 150, width: 100, height: 100),
        BoxElement(id: 'far', x: 500, y: 400, width: 50, height: 50),
      ],
    );

void main() {
  group('hit testing', () {
    test('returns top-most element and null on empty space', () {
      final c = EditorController(document: _doc());
      expect(c.hitTest(const Offset(160, 160))!.id, 'front');
      expect(c.hitTest(const Offset(110, 110))!.id, 'back');
      expect(c.hitTest(const Offset(700, 50)), isNull);
    });

    test('handles are found only for the selection', () {
      final c = EditorController(document: _doc())..select('far');
      expect(c.hitTestHandle(const Offset(550, 450), 12), ResizeHandle.bottomRight);
      expect(c.hitTestHandle(const Offset(525, 400), 12), ResizeHandle.top);
      expect(c.hitTestHandle(const Offset(300, 200), 12), isNull);
    });
  });

  group('drag move', () {
    test('moves by delta with grid snapping and selects the element', () {
      final c = EditorController(document: _doc(), snapGrid: 8, guideThreshold: 0);
      expect(c.beginDrag(const Offset(520, 420)), isTrue);
      expect(c.selectedId, 'far');
      c.updateDrag(const Offset(533, 431)); // delta 13,11 → 513,411 → snap 512,408
      c.endDrag();
      final b = c.selectedBounds!;
      expect((b.left, b.top), (512.0, 408.0));
      expect(c.isDragging, isFalse);
    });

    test('snaps to another element edge within threshold and reports guide', () {
      final c = EditorController(document: _doc(), snapGrid: 0, guideThreshold: 4);
      c.beginDrag(const Offset(520, 420));
      // far.left=500 → 303 is 3 dots from back.right (300).
      c.updateDrag(const Offset(323, 420));
      expect(c.selectedBounds!.left, 300);
      expect(c.activeGuidesX, [300.0]);
      c.endDrag();
      expect(c.activeGuidesX, isEmpty);
    });

    test('is clamped inside the label', () {
      final c = EditorController(document: _doc(), snapGrid: 0, guideThreshold: 0);
      c.beginDrag(const Offset(520, 420));
      c.updateDrag(const Offset(2000, -2000));
      final b = c.selectedBounds!;
      expect((b.left, b.top), (750.0, 0.0));
    });

    test('empty-space drag clears selection and returns false', () {
      final c = EditorController(document: _doc())..select('far');
      expect(c.beginDrag(const Offset(700, 50)), isFalse);
      expect(c.selectedId, isNull);
    });
  });

  group('drag resize', () {
    test('bottom-right handle grows the box', () {
      final c = EditorController(document: _doc(), snapGrid: 0, guideThreshold: 0)
        ..select('far');
      c.beginDrag(const Offset(550, 450));
      c.updateDrag(const Offset(580, 470));
      c.endDrag();
      final e = c.selected as BoxElement;
      expect((e.x, e.y, e.width, e.height), (500, 400, 80, 70));
    });

    test('top-left handle moves origin and shrinks, never below min size', () {
      final c = EditorController(document: _doc(), snapGrid: 0, guideThreshold: 0)
        ..select('far');
      c.beginDrag(const Offset(500, 400));
      c.updateDrag(const Offset(510, 410));
      var e = c.selected as BoxElement;
      expect((e.x, e.y, e.width, e.height), (510, 410, 40, 40));
      c.updateDrag(const Offset(900, 900));
      e = c.selected as BoxElement;
      expect(e.width >= 4 && e.height >= 4, isTrue);
    });
  });

  group('document ops', () {
    test('add, nudge, z-order, remove', () {
      final c = EditorController(document: _doc(), snapGrid: 0);
      c.addElement(const CircleElement(id: 'c', x: 10, y: 10, diameter: 20));
      expect(c.selectedId, 'c');
      c.nudgeSelected(-50, 5);
      expect((c.selected!.x, c.selected!.y), (0, 15));
      c.sendBackward();
      expect(c.document.elements[2].id, 'c');
      c.removeSelected();
      expect(c.selected, isNull);
      expect(c.document.elements.length, 3);
    });

    test('setDocument drops selection of a missing element', () {
      final c = EditorController(document: _doc())..select('far');
      c.setDocument(const LabelDocument());
      expect(c.selectedId, isNull);
    });
  });

  group('history and duplicate', () {
    test('undo/redo restore snapshots, drag is one step', () {
      final c = EditorController(document: _doc(), snapGrid: 0, guideThreshold: 0);
      expect(c.canUndo, isFalse);
      c.beginDrag(const Offset(520, 420));
      c.updateDrag(const Offset(530, 420));
      c.updateDrag(const Offset(540, 420));
      c.endDrag();
      expect(c.selected!.x, 520);
      c.undo();
      expect(c.document.elementById('far')!.x, 500);
      expect(c.canUndo, isFalse);
      c.redo();
      expect(c.document.elementById('far')!.x, 520);
      c.removeSelected();
      c.undo();
      expect(c.document.elementById('far'), isNotNull);
    });

    test('duplicate copies properties with new id and offset', () {
      final c = EditorController(document: _doc())..select('far');
      c.duplicateSelected();
      final copy = c.selected as BoxElement;
      expect(copy.id, isNot('far'));
      expect((copy.x, copy.y, copy.width), (516, 416, 50));
      expect(c.document.elements.length, 4);
    });

    test('loadDocument clears history', () {
      final c = EditorController(document: _doc());
      c.addElement(const CircleElement(id: 'c'));
      c.loadDocument(const LabelDocument());
      expect(c.canUndo, isFalse);
    });
  });

  group('review follow-ups', () {
    test('coalesced updates form one undo step; a click without move adds none', () {
      final c = EditorController(document: _doc())..select('far');
      c.updateSelected((e) => (e as BoxElement).copyWith(width: 51), coalesce: 'inspector:far');
      c.updateSelected((e) => (e as BoxElement).copyWith(width: 52), coalesce: 'inspector:far');
      c.updateSelected((e) => (e as BoxElement).copyWith(width: 53), coalesce: 'inspector:far');
      c.undo();
      expect((c.selected as BoxElement).width, 50);
      expect(c.canUndo, isFalse);

      c.beginDrag(const Offset(520, 420));
      c.endDrag();
      expect(c.canUndo, isFalse);
    });

    test('resize cannot grow past the label edge', () {
      final c = EditorController(document: _doc(), snapGrid: 0, guideThreshold: 0)..select('far');
      c.beginDrag(const Offset(550, 450));
      c.updateDrag(const Offset(2000, 2000));
      final b = c.selectedBounds!;
      expect(b.right, 800);
      expect(b.bottom, 600);
    });
  });
}
