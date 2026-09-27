import 'dart:ui';

import 'resize_handle.dart';

/// Result of snapping: the adjusted rect plus the guide lines that were hit.
typedef SnapResult = ({Rect rect, List<double> guidesX, List<double> guidesY});

/// Pure snapping logic: alignment guides (other elements' edges/centres and
/// the label's edges/centre) win over the grid because they are what users
/// aim for; the grid only applies to axes that found no guide.
class SnapEngine {
  final int snapGrid;
  final int guideThreshold;
  final List<double> _xs;
  final List<double> _ys;

  SnapEngine({
    required this.snapGrid,
    required this.guideThreshold,
    required Iterable<Rect> others,
    required Size label,
  })  : _xs = [
          for (final b in others) ...[b.left, b.center.dx, b.right],
          0,
          label.width / 2,
          label.width,
        ],
        _ys = [
          for (final b in others) ...[b.top, b.center.dy, b.bottom],
          0,
          label.height / 2,
          label.height,
        ];

  /// Snaps a whole-rect move.
  SnapResult move(Rect r) {
    final sx = _nearest(_xs, [r.left, r.center.dx, r.right]);
    final sy = _nearest(_ys, [r.top, r.center.dy, r.bottom]);
    var out = r.shift(Offset(sx?.delta ?? 0, sy?.delta ?? 0));
    out = Rect.fromLTWH(
      sx == null ? _grid(out.left) : out.left,
      sy == null ? _grid(out.top) : out.top,
      out.width,
      out.height,
    );
    return (
      rect: out,
      guidesX: [if (sx != null) sx.guide],
      guidesY: [if (sy != null) sy.guide],
    );
  }

  /// Snaps only the edges moved by [handle]; never shrinks below [minSize].
  SnapResult resize(Rect r, ResizeHandle handle, {double minSize = 4}) {
    final guidesX = <double>[];
    final guidesY = <double>[];
    double edge(double v, List<double> guides, List<double> out) {
      final s = _nearest(guides, [v]);
      if (s == null) return _grid(v);
      out.add(s.guide);
      return v + s.delta;
    }

    var left = r.left, top = r.top, right = r.right, bottom = r.bottom;
    if (handle.movesLeft) left = edge(left, _xs, guidesX);
    if (handle.movesRight) right = edge(right, _xs, guidesX);
    if (handle.movesTop) top = edge(top, _ys, guidesY);
    if (handle.movesBottom) bottom = edge(bottom, _ys, guidesY);
    final out = (right - left >= minSize && bottom - top >= minSize)
        ? Rect.fromLTRB(left, top, right, bottom)
        : r;
    return (rect: out, guidesX: guidesX, guidesY: guidesY);
  }

  double _grid(double v) =>
      snapGrid > 0 ? (v / snapGrid).round() * snapGrid.toDouble() : v;

  ({double guide, double delta})? _nearest(
    List<double> guides,
    List<double> candidates,
  ) {
    ({double guide, double delta})? best;
    for (final c in candidates) {
      for (final g in guides) {
        final d = g - c;
        if (d.abs() <= guideThreshold &&
            (best == null || d.abs() < best.delta.abs())) {
          best = (guide: g, delta: d);
        }
      }
    }
    return best;
  }
}
