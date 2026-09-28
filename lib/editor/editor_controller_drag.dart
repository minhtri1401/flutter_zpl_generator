part of 'editor_controller.dart';

/// In-progress move/resize: start bounds of every dragged element.
class _DragSession {
  final Map<String, Rect> starts;
  final Rect unionStart;
  final Offset origin;
  final ResizeHandle? handle;
  final LabelDocument startDocument;
  bool committed = false;

  _DragSession({
    required this.starts,
    required this.origin,
    required this.handle,
    required this.startDocument,
  }) : unionStart = starts.values.reduce((a, b) => a.expandToInclude(b));

  String get primaryId => starts.keys.last;
}

/// Pointer-driven move, resize and marquee selection.
extension EditorControllerDrag on EditorController {
  bool get isDragging => _drag != null;

  /// Marquee rectangle being drawn, in dots.
  Rect? get marquee => _marquee;

  /// Handle under [point] for a single selection, if any.
  ResizeHandle? hitTestHandle(Offset point, double handleSize) {
    if (hasMultipleSelected) return null;
    final rect = selectedBounds;
    if (rect == null) return null;
    return ResizeHandle.hitTest(rect, point, handleSize);
  }

  /// Starts a move or resize. Returns false when nothing is under [point]
  /// (the caller then pans or, with [additive], starts a marquee).
  /// Dragging an element that is already selected moves the whole selection;
  /// dragging an unselected one selects it first ([additive] keeps the rest).
  bool beginDrag(
    Offset point, {
    double handleSize = 12,
    bool additive = false,
  }) {
    _lastCoalesceKey = null;
    final handle = hitTestHandle(point, handleSize);
    if (handle != null) {
      _drag = _DragSession(
        starts: {selectedId!: selectedBounds!},
        origin: point,
        handle: handle,
        startDocument: _document,
      );
      return true;
    }
    final hit = hitTest(point);
    if (hit == null) {
      if (!additive) select(null);
      return false;
    }
    if (!_selection.contains(hit.id)) {
      if (!additive) _selection.clear();
      _selection.add(hit.id);
    }
    _drag = _DragSession(
      starts: {for (final e in selectedElements) e.id: e.bounds(config)},
      origin: point,
      handle: null,
      startDocument: _document,
    );
    _notify();
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
    final snap = _snapEngine(drag.starts.keys.toSet());

    if (drag.handle != null) {
      final id = drag.primaryId;
      final start = drag.starts[id]!;
      final snapped = snap.resize(
        drag.handle!.apply(start, delta),
        drag.handle!,
      );
      activeGuidesX = snapped.guidesX;
      activeGuidesY = snapped.guidesY;
      final target = _clampResizeToLabel(snapped.rect, start);
      _document = _document.update(
        id,
        (e) => e
            .moveTo(target.left.round(), target.top.round())
            .resizeTo(target.width.round(), target.height.round()),
      );
    } else {
      final snapped = snap.move(drag.unionStart.shift(delta));
      activeGuidesX = snapped.guidesX;
      activeGuidesY = snapped.guidesY;
      final target = _clampToLabel(snapped.rect);
      final dx = (target.left - drag.unionStart.left).round();
      final dy = (target.top - drag.unionStart.top).round();
      for (final entry in drag.starts.entries) {
        final s = entry.value;
        _document = _document.update(
          entry.key,
          (e) => e.moveTo(s.left.round() + dx, s.top.round() + dy),
        );
      }
    }
    _notify();
  }

  void endDrag() {
    if (_drag == null) return;
    _drag = null;
    activeGuidesX = const [];
    activeGuidesY = const [];
    _notify();
  }

  void beginMarquee(Offset point) {
    _marqueeOrigin = point;
    _marquee = Rect.fromPoints(point, point);
    _notify();
  }

  void updateMarquee(Offset point) {
    final origin = _marqueeOrigin;
    if (origin == null) return;
    _marquee = Rect.fromPoints(origin, point);
    _notify();
  }

  /// Selects what the marquee covers; [additive] keeps the prior selection.
  void endMarquee({bool additive = false}) {
    final rect = _marquee;
    _marquee = null;
    _marqueeOrigin = null;
    if (rect == null) return;
    selectInRect(rect, additive: additive);
  }

  /// Resizing keeps every edge inside the label; if that would violate the
  /// minimum size the previous rect is kept.
  Rect _clampResizeToLabel(Rect r, Rect fallback) {
    final clipped = r.intersect(_labelRect);
    return (clipped.width >= 4 && clipped.height >= 4) ? clipped : fallback;
  }

  SnapEngine _snapEngine(Set<String> dragged) => SnapEngine(
    snapGrid: snapGrid,
    guideThreshold: guideThreshold,
    others: [
      for (final e in _document.elements)
        if (!dragged.contains(e.id)) e.bounds(config),
    ],
    label: Size(_document.width.toDouble(), _document.height.toDouble()),
  );
}
