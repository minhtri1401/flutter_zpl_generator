import 'dart:ui';

/// The eight resize handles around a selected element.
enum ResizeHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left;

  bool get movesLeft => this == topLeft || this == left || this == bottomLeft;
  bool get movesRight =>
      this == topRight || this == right || this == bottomRight;
  bool get movesTop => this == topLeft || this == top || this == topRight;
  bool get movesBottom =>
      this == bottomLeft || this == bottom || this == bottomRight;

  /// Anchor point of this handle on [rect].
  Offset anchor(Rect rect) => switch (this) {
    topLeft => rect.topLeft,
    top => rect.topCenter,
    topRight => rect.topRight,
    right => rect.centerRight,
    bottomRight => rect.bottomRight,
    bottom => rect.bottomCenter,
    bottomLeft => rect.bottomLeft,
    left => rect.centerLeft,
  };

  /// Applies a drag [delta] to [rect], keeping at least [minSize] on each axis.
  Rect apply(Rect rect, Offset delta, {double minSize = 4}) {
    var left = rect.left;
    var top = rect.top;
    var right = rect.right;
    var bottom = rect.bottom;
    if (movesLeft) {
      left = (left + delta.dx).clamp(double.negativeInfinity, right - minSize);
    }
    if (movesRight) {
      right = (right + delta.dx).clamp(left + minSize, double.infinity);
    }
    if (movesTop) {
      top = (top + delta.dy).clamp(double.negativeInfinity, bottom - minSize);
    }
    if (movesBottom) {
      bottom = (bottom + delta.dy).clamp(top + minSize, double.infinity);
    }
    return Rect.fromLTRB(left, top, right, bottom);
  }

  /// Returns the handle whose hit area (a square of [size] dots centred on
  /// its anchor) contains [point], or null.
  static ResizeHandle? hitTest(Rect rect, Offset point, double size) {
    for (final h in values) {
      if (Rect.fromCenter(
        center: h.anchor(rect),
        width: size,
        height: size,
      ).contains(point)) {
        return h;
      }
    }
    return null;
  }
}
