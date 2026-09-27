import 'model/label_document.dart';

/// Snapshot-based undo/redo. Documents are immutable, so storing references
/// is cheap; only the element list is copied on each mutation.
class EditorHistory {
  final int capacity;
  final List<LabelDocument> _undo = [];
  final List<LabelDocument> _redo = [];

  EditorHistory({this.capacity = 100});

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  /// Records [current] as the state to return to on the next undo.
  void push(LabelDocument current) {
    _undo.add(current);
    if (_undo.length > capacity) _undo.removeAt(0);
    _redo.clear();
  }

  LabelDocument? undo(LabelDocument current) {
    if (_undo.isEmpty) return null;
    _redo.add(current);
    return _undo.removeLast();
  }

  LabelDocument? redo(LabelDocument current) {
    if (_redo.isEmpty) return null;
    _undo.add(current);
    return _redo.removeLast();
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
