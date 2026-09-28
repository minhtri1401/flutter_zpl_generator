import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'canvas/resize_handle.dart';
import 'canvas/snap_engine.dart';
import 'editor_history.dart';
import 'model/element_json_codec.dart';
import 'model/label_document.dart';
import 'model/label_element.dart';
import 'model/label_preset.dart';
import 'storage/template_store.dart';

/// Owns the editor state: document, selection and in-progress gestures.
///
/// All coordinates are label dots. Gestures call [beginDrag]/[updateDrag]/
/// [endDrag]; the widget layer converts pointer positions to dots.
class EditorController extends ChangeNotifier {
  LabelDocument _document;
  String? _selectedId;

  /// Grid step in dots used for snapping; 0 disables snapping.
  int snapGrid;

  /// Distance in dots within which an edge/centre snaps to another element.
  int guideThreshold;

  /// Alignment guide lines to draw during a drag (x positions and y positions).
  List<double> activeGuidesX = const [];
  List<double> activeGuidesY = const [];

  _DragSession? _drag;
  final EditorHistory _history = EditorHistory();
  Object? _lastCoalesceKey;
  EditorUnits _units = EditorUnits.dots;
  TemplateInfo? _currentTemplate;

  EditorController({
    LabelDocument? document,
    this.snapGrid = 8,
    this.guideThreshold = 4,
  }) : _document = document ?? const LabelDocument();

  LabelDocument get document => _document;
  ZplConfiguration get config => _document.config;
  String? get selectedId => _selectedId;
  LabelElement? get selected =>
      _selectedId == null ? null : _document.elementById(_selectedId!);
  Rect? get selectedBounds => selected?.bounds(config);
  bool get isDragging => _drag != null;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

  /// Display units for inspector helper text and rulers (not persisted).
  EditorUnits get units => _units;
  set units(EditorUnits value) {
    if (value == _units) return;
    _units = value;
    notifyListeners();
  }

  /// Dots per millimetre from the label's print density (8 when unset).
  double get dpmm => dpmmFor(config.printDensity);

  /// [dots] expressed in the current display units, e.g. "12.7 mm".
  String formatDots(int dots) => _units.format(dots, dpmm);

  /// Records the current document before a user-visible mutation.
  /// Consecutive commits sharing a non-null [coalesce] key (typing in one
  /// field, repeated nudges) collapse into a single undo step.
  void _commit({Object? coalesce}) {
    if (coalesce != null && coalesce == _lastCoalesceKey) return;
    _lastCoalesceKey = coalesce;
    _history.push(_document);
  }

  void undo() {
    _lastCoalesceKey = null;
    final prev = _history.undo(_document);
    if (prev != null) setDocument(prev);
  }

  void redo() {
    _lastCoalesceKey = null;
    final next = _history.redo(_document);
    if (next != null) setDocument(next);
  }

  /// Loads a document as a fresh starting point (clears history).
  void loadDocument(LabelDocument doc) {
    _history.clear();
    setDocument(doc);
  }

  /// The saved template this document came from, if any.
  TemplateInfo? get currentTemplate => _currentTemplate;

  /// Loads [doc] and remembers it as [info] (null for imported/unsaved).
  void loadTemplate(TemplateInfo? info, LabelDocument doc) {
    _currentTemplate = info;
    loadDocument(doc);
  }

  /// Records that the current document was saved as [info].
  void markSaved(TemplateInfo? info) {
    _currentTemplate = info;
    notifyListeners();
  }

  /// Replaces the document (undo/redo, load) and drops stale selection.
  void setDocument(LabelDocument doc) {
    _document = doc;
    if (_selectedId != null && doc.elementById(_selectedId!) == null) {
      _selectedId = null;
    }
    notifyListeners();
  }

  void setConfig(ZplConfiguration config) {
    _commit();
    setDocument(_document.copyWith(config: config));
  }

  void select(String? id) {
    if (_selectedId == id) return;
    _lastCoalesceKey = null;
    _selectedId = id;
    notifyListeners();
  }

  void addElement(LabelElement element, {bool select = true}) {
    _commit();
    _document = _document.add(element);
    if (select) _selectedId = element.id;
    notifyListeners();
  }

  void removeSelected() {
    if (_selectedId == null) return;
    _commit();
    _document = _document.remove(_selectedId!);
    _selectedId = null;
    notifyListeners();
  }

  /// [coalesce] merges this change with the previous one that used the same
  /// key (see [_commit]).
  void updateSelected(
    LabelElement Function(LabelElement e) update, {
    Object? coalesce,
  }) {
    if (_selectedId == null) return;
    _commit(coalesce: coalesce);
    _document = _document.update(_selectedId!, update);
    notifyListeners();
  }

  void bringForward() {
    if (_selectedId == null) return;
    _commit();
    setDocument(_document.bringForward(_selectedId!));
  }

  void sendBackward() {
    if (_selectedId == null) return;
    _commit();
    setDocument(_document.sendBackward(_selectedId!));
  }

  /// Top-most element under [point], or null.
  LabelElement? hitTest(Offset point) {
    for (final e in _document.elements.reversed) {
      if (e.bounds(config).contains(point)) return e;
    }
    return null;
  }

  /// Handle under [point] for the current selection, if any.
  ResizeHandle? hitTestHandle(Offset point, double handleSize) {
    final rect = selectedBounds;
    if (rect == null) return null;
    return ResizeHandle.hitTest(rect, point, handleSize);
  }

  /// Starts a move or resize. Returns false when nothing is under [point]
  /// (caller should clear selection).
  bool beginDrag(Offset point, {double handleSize = 12}) {
    final handle = hitTestHandle(point, handleSize);
    _lastCoalesceKey = null;
    if (handle != null && selected != null) {
      _drag = _DragSession(selected!, selectedBounds!, point, handle, _document);
      return true;
    }
    final hit = hitTest(point);
    if (hit == null) {
      select(null);
      return false;
    }
    _selectedId = hit.id;
    _drag = _DragSession(hit, hit.bounds(config), point, null, _document);
    notifyListeners();
    return true;
  }

  void updateDrag(Offset point) {
    final drag = _drag;
    if (drag == null) return;
    // History entry is pushed on first movement, so a click without a drag
    // does not create an undo step.
    if (!drag.committed) {
      _history.push(drag.startDocument);
      drag.committed = true;
    }
    final delta = point - drag.origin;
    final snap = _snapEngine(drag.element.id);
    final SnapResult snapped = drag.handle == null
        ? snap.move(drag.startBounds.shift(delta))
        : snap.resize(drag.handle!.apply(drag.startBounds, delta), drag.handle!);
    activeGuidesX = snapped.guidesX;
    activeGuidesY = snapped.guidesY;
    final target = drag.handle == null
        ? _clampToLabel(snapped.rect)
        : _clampResizeToLabel(snapped.rect, drag.startBounds);

    var updated = drag.element.moveTo(target.left.round(), target.top.round());
    if (drag.handle != null) {
      updated = updated.resizeTo(target.width.round(), target.height.round());
    }
    _document = _document.update(drag.element.id, (_) => updated);
    notifyListeners();
  }

  void endDrag() {
    if (_drag == null) return;
    _drag = null;
    activeGuidesX = const [];
    activeGuidesY = const [];
    notifyListeners();
  }

  /// Nudges the selection by whole dots (keyboard arrows).
  void nudgeSelected(int dx, int dy) {
    final e = selected;
    if (e == null) return;
    final r = _clampToLabel(e.bounds(config).shift(Offset(dx.toDouble(), dy.toDouble())));
    updateSelected(
      (el) => el.moveTo(r.left.round(), r.top.round()),
      coalesce: 'nudge:${e.id}',
    );
  }

  /// Resizing keeps every edge inside the label; if that would violate the
  /// minimum size the previous rect is kept.
  Rect _clampResizeToLabel(Rect r, Rect fallback) {
    final label = Rect.fromLTWH(
      0,
      0,
      _document.width.toDouble(),
      _document.height.toDouble(),
    );
    final clipped = r.intersect(label);
    return (clipped.width >= 4 && clipped.height >= 4) ? clipped : fallback;
  }

  /// Copies the selection with a new id, offset by 16 dots.
  void duplicateSelected() {
    final e = selected;
    if (e == null) return;
    final json = ElementJsonCodec.encode(e)
      ..['id'] = ElementId.next(e.typeName)
      ..['x'] = e.x + 16
      ..['y'] = e.y + 16;
    final copy = ElementJsonCodec.decode(json);
    if (copy != null) addElement(copy);
  }

  Rect _clampToLabel(Rect r) {
    final w = _document.width.toDouble();
    final h = _document.height.toDouble();
    final left = r.left.clamp(0.0, (w - r.width).clamp(0.0, w));
    final top = r.top.clamp(0.0, (h - r.height).clamp(0.0, h));
    return Rect.fromLTWH(left, top, r.width, r.height);
  }

  SnapEngine _snapEngine(String selfId) => SnapEngine(
        snapGrid: snapGrid,
        guideThreshold: guideThreshold,
        others: [
          for (final e in _document.elements)
            if (e.id != selfId) e.bounds(config),
        ],
        label: Size(_document.width.toDouble(), _document.height.toDouble()),
      );
}

class _DragSession {
  final LabelElement element;
  final Rect startBounds;
  final Offset origin;
  final ResizeHandle? handle;
  final LabelDocument startDocument;
  bool committed = false;
  _DragSession(
    this.element,
    this.startBounds,
    this.origin,
    this.handle,
    this.startDocument,
  );
}
