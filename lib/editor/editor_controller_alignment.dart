part of 'editor_controller.dart';

/// Align/distribute operations on the selection.
enum AlignOp {
  left('Align left'),
  centerX('Align centre'),
  right('Align right'),
  top('Align top'),
  centerY('Align middle'),
  bottom('Align bottom'),
  distributeH('Distribute horizontally'),
  distributeV('Distribute vertically');

  final String label;
  const AlignOp(this.label);

  bool get isDistribute => this == distributeH || this == distributeV;
}

extension EditorControllerAlignment on EditorController {
  /// Distribution needs three or more elements.
  bool get canDistribute => _selection.length >= 3;

  /// A single element aligns to the label; several align to their union.
  void alignSelected(AlignOp op) {
    final elements = selectedElements;
    if (elements.isEmpty) return;
    if (op.isDistribute) {
      if (!canDistribute) return;
      _commit();
      _distribute(elements, horizontal: op == AlignOp.distributeH);
      _notify();
      return;
    }
    final frame = elements.length == 1 ? _labelRect : selectionBounds!;
    _commit();
    for (final e in elements) {
      final b = e.bounds(config);
      final target = switch (op) {
        AlignOp.left => b.shift(Offset(frame.left - b.left, 0)),
        AlignOp.centerX => b.shift(Offset(frame.center.dx - b.center.dx, 0)),
        AlignOp.right => b.shift(Offset(frame.right - b.right, 0)),
        AlignOp.top => b.shift(Offset(0, frame.top - b.top)),
        AlignOp.centerY => b.shift(Offset(0, frame.center.dy - b.center.dy)),
        AlignOp.bottom => b.shift(Offset(0, frame.bottom - b.bottom)),
        _ => b,
      };
      _document = _document.update(
        e.id,
        (el) => el.moveTo(target.left.round(), target.top.round()),
      );
    }
    _notify();
  }

  /// Keeps the first and last element in place and spaces the rest so the
  /// gaps between neighbours are equal.
  void _distribute(List<LabelElement> elements, {required bool horizontal}) {
    final sorted = [...elements]
      ..sort((a, b) {
        final ba = a.bounds(config);
        final bb = b.bounds(config);
        return horizontal
            ? ba.left.compareTo(bb.left)
            : ba.top.compareTo(bb.top);
      });
    final bounds = [for (final e in sorted) e.bounds(config)];
    final first = bounds.first;
    final last = bounds.last;
    final span = horizontal ? last.right - first.left : last.bottom - first.top;
    final occupied = bounds.fold<double>(
      0,
      (sum, b) => sum + (horizontal ? b.width : b.height),
    );
    final gap = (span - occupied) / (bounds.length - 1);
    var cursor = horizontal ? first.right : first.bottom;
    for (var i = 1; i < sorted.length - 1; i++) {
      final b = bounds[i];
      final pos = cursor + gap;
      final target = horizontal
          ? Rect.fromLTWH(pos, b.top, b.width, b.height)
          : Rect.fromLTWH(b.left, pos, b.width, b.height);
      _document = _document.update(
        sorted[i].id,
        (el) => el.moveTo(target.left.round(), target.top.round()),
      );
      cursor = horizontal ? target.right : target.bottom;
    }
  }
}
