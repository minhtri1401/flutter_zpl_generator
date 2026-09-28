import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'resize_handle.dart';

/// Draws every selected element's box, resize handles on the primary one
/// (single selection only), active alignment guides and the marquee.
/// [handleSize] is in dots (already divided by zoom so handles stay a
/// constant on-screen size).
class SelectionOverlayPainter extends CustomPainter {
  final Rect? selection;
  final List<Rect> others;
  final bool showHandles;
  final Rect? marquee;
  final double handleSize;
  final List<double> guidesX;
  final List<double> guidesY;

  SelectionOverlayPainter({
    required this.selection,
    required this.handleSize,
    this.others = const [],
    this.showHandles = true,
    this.marquee,
    this.guidesX = const [],
    this.guidesY = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = Colors.pinkAccent
      ..strokeWidth = handleSize / 8;
    for (final x in guidesX) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), guidePaint);
    }
    for (final y in guidesY) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    final border = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = handleSize / 6;
    for (final r in others) {
      canvas.drawRect(r, border);
    }

    final rect = selection;
    if (rect != null) {
      canvas.drawRect(rect, border);
      if (showHandles) {
        final fill = Paint()..color = Colors.white;
        for (final h in ResizeHandle.values) {
          final r = Rect.fromCenter(
            center: h.anchor(rect),
            width: handleSize,
            height: handleSize,
          );
          canvas.drawRect(r, fill);
          canvas.drawRect(r, border);
        }
      }
    }

    final m = marquee;
    if (m != null) {
      canvas.drawRect(
        m,
        Paint()..color = Colors.blueAccent.withValues(alpha: 0.12),
      );
      canvas.drawRect(m, border);
    }
  }

  @override
  bool shouldRepaint(SelectionOverlayPainter old) =>
      old.selection != selection ||
      old.showHandles != showHandles ||
      old.marquee != marquee ||
      old.handleSize != handleSize ||
      !listEquals(old.others, others) ||
      !listEquals(old.guidesX, guidesX) ||
      !listEquals(old.guidesY, guidesY);
}
