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

part 'editor_controller_alignment.dart';
part 'editor_controller_drag.dart';

/// Owns the editor state: document, selection, in-progress gestures,
/// history, display units and the current template.
///
/// All coordinates are label dots. The selection is an ordered set; the
/// last picked element is the *primary* one shown in the inspector and the
/// only one that gets resize handles. Drag/marquee live in
/// `editor_controller_drag.dart`, align/distribute in
/// `editor_controller_alignment.dart`.
class EditorController extends ChangeNotifier {
  LabelDocument _document;
  final List<String> _selection = [];
  bool _multiSelectMode = false;

  /// Grid step in dots used for snapping; 0 disables snapping.
  int snapGrid;

  /// Distance in dots within which an edge/centre snaps to another element.
  int guideThreshold;

  /// Alignment guide lines to draw during a drag (x positions and y positions).
  List<double> activeGuidesX = const [];
  List<double> activeGuidesY = const [];

  _DragSession? _drag;
  Offset? _marqueeOrigin;
  Rect? _marquee;
  final EditorHistory _history = EditorHistory();
  Object? _lastCoalesceKey;
  EditorUnits _units = EditorUnits.dots;
  TemplateInfo? _currentTemplate;

  EditorController({
    LabelDocument? document,
    this.snapGrid = 8,
    this.guideThreshold = 4,
  }) : _document = document ?? const LabelDocument();

  /// Lets the part files (extensions) notify without touching the
  /// protected [notifyListeners] directly.
  void _notify() => notifyListeners();

  // ---------------------------------------------------------------- document

  LabelDocument get document => _document;
  ZplConfiguration get config => _document.config;
  bool get canUndo => _history.canUndo;
  bool get canRedo => _history.canRedo;

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

  /// Replaces the document (undo/redo, load) and drops stale selection.
  void setDocument(LabelDocument doc) {
    _document = doc;
    _selection.removeWhere((id) => doc.elementById(id) == null);
    notifyListeners();
  }

  void setConfig(ZplConfiguration config) {
    _commit();
    setDocument(_document.copyWith(config: config));
  }

  /// Stores a sample value for a placeholder (one undo step per variable).
  void setSampleValue(String name, String value) {
    _commit(coalesce: 'sample:$name');
    _document = _document.withSample(name, value);
    notifyListeners();
  }

  // --------------------------------------------------------------- templates

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

  // ------------------------------------------------------------------- units

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

  // --------------------------------------------------------------- selection

  /// Selected ids in pick order; the last one is the primary element.
  List<String> get selectedIds => List.unmodifiable(_selection);
  String? get selectedId => _selection.isEmpty ? null : _selection.last;
  LabelElement? get selected =>
      selectedId == null ? null : _document.elementById(selectedId!);
  List<LabelElement> get selectedElements => [
    for (final id in _selection) ?_document.elementById(id),
  ];
  bool get hasMultipleSelected => _selection.length > 1;

  /// Bounds of the primary element (handles are drawn on it).
  Rect? get selectedBounds => selected?.bounds(config);

  /// Union of every selected element's bounds.
  Rect? get selectionBounds {
    Rect? union;
    for (final e in selectedElements) {
      final b = e.bounds(config);
      union = union == null ? b : union.expandToInclude(b);
    }
    return union;
  }

  /// When true, taps toggle membership and empty-space drags draw a marquee.
  bool get multiSelectMode => _multiSelectMode;
  set multiSelectMode(bool value) {
    if (value == _multiSelectMode) return;
    _multiSelectMode = value;
    notifyListeners();
  }

  /// Replaces the selection with [id] (null clears it).
  void select(String? id) {
    if (id == null
        ? _selection.isEmpty
        : (_selection.length == 1 && _selection.single == id)) {
      return;
    }
    _lastCoalesceKey = null;
    _selection
      ..clear()
      ..addAll([?id]);
    notifyListeners();
  }

  /// Adds [id] to the selection, or removes it when already selected.
  void toggleSelect(String id) {
    _lastCoalesceKey = null;
    if (!_selection.remove(id)) _selection.add(id);
    notifyListeners();
  }

  void selectAll() {
    _lastCoalesceKey = null;
    _selection
      ..clear()
      ..addAll(_document.elements.map((e) => e.id));
    notifyListeners();
  }

  /// Selects every element whose bounds overlap [rect]; [additive] keeps
  /// the existing selection.
  void selectInRect(Rect rect, {bool additive = false}) {
    _lastCoalesceKey = null;
    if (!additive) _selection.clear();
    for (final e in _document.elements) {
      if (e.bounds(config).overlaps(rect) && !_selection.contains(e.id)) {
        _selection.add(e.id);
      }
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------- elements

  void addElement(LabelElement element, {bool select = true}) {
    _commit();
    _document = _document.add(element);
    if (select) {
      _selection
        ..clear()
        ..add(element.id);
    }
    notifyListeners();
  }

  /// Deletes every selected element.
  void removeSelected() {
    if (_selection.isEmpty) return;
    _commit();
    for (final id in _selection) {
      _document = _document.remove(id);
    }
    _selection.clear();
    notifyListeners();
  }

  /// Edits the primary element. [coalesce] merges this change with the
  /// previous one that used the same key (see [_commit]).
  void updateSelected(
    LabelElement Function(LabelElement e) update, {
    Object? coalesce,
  }) {
    final id = selectedId;
    if (id == null) return;
    _commit(coalesce: coalesce);
    _document = _document.update(id, update);
    notifyListeners();
  }

  void bringForward() => _reorder(forward: true);

  void sendBackward() => _reorder(forward: false);

  /// Moves every selected element one step; processed from the end (or the
  /// start) so a contiguous group keeps its internal order.
  void _reorder({required bool forward}) {
    if (_selection.isEmpty) return;
    _commit();
    final ids = _document.elements
        .map((e) => e.id)
        .where(_selection.contains)
        .toList();
    for (final id in forward ? ids.reversed : ids) {
      _document = forward
          ? _document.bringForward(id)
          : _document.sendBackward(id);
    }
    notifyListeners();
  }

  /// Copies every selected element with a new id, offset by 16 dots; the
  /// copies become the selection.
  void duplicateSelected() {
    final sources = selectedElements;
    if (sources.isEmpty) return;
    _commit();
    final copies = <String>[];
    for (final e in sources) {
      final json = ElementJsonCodec.encode(e)
        ..['id'] = ElementId.next(e.typeName)
        ..['x'] = e.x + 16
        ..['y'] = e.y + 16;
      final copy = ElementJsonCodec.decode(json);
      if (copy == null) continue;
      _document = _document.add(copy);
      copies.add(copy.id);
    }
    _selection
      ..clear()
      ..addAll(copies);
    notifyListeners();
  }

  /// Nudges the whole selection by whole dots (keyboard arrows).
  void nudgeSelected(int dx, int dy) {
    final union = selectionBounds;
    if (union == null) return;
    final clamped = _clampToLabel(
      union.shift(Offset(dx.toDouble(), dy.toDouble())),
    );
    final ddx = (clamped.left - union.left).round();
    final ddy = (clamped.top - union.top).round();
    if (ddx == 0 && ddy == 0) return;
    _commit(coalesce: 'nudge:${_selection.join(',')}');
    for (final e in selectedElements) {
      _document = _document.update(
        e.id,
        (el) => el.moveTo(el.x + ddx, el.y + ddy),
      );
    }
    notifyListeners();
  }

  /// Top-most element under [point], or null.
  LabelElement? hitTest(Offset point) {
    for (final e in _document.elements.reversed) {
      if (e.bounds(config).contains(point)) return e;
    }
    return null;
  }

  Rect get _labelRect => Rect.fromLTWH(
    0,
    0,
    _document.width.toDouble(),
    _document.height.toDouble(),
  );

  Rect _clampToLabel(Rect r) {
    final w = _document.width.toDouble();
    final h = _document.height.toDouble();
    final left = r.left.clamp(0.0, (w - r.width).clamp(0.0, w));
    final top = r.top.clamp(0.0, (h - r.height).clamp(0.0, h));
    return Rect.fromLTWH(left, top, r.width, r.height);
  }
}
