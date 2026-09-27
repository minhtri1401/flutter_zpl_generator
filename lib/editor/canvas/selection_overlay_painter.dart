import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'resize_handle.dart';

/// Draws the selection box, its eight handles and active alignment guides.
/// [handleSize] is in dots (already divided by zoom so handles stay a
/// constant on-screen size).
class SelectionOverlayPainter extends CustomPainter {
  final Rect? selection;
  final double handleSize;
  final List<double> guidesX;
  final List<double> guidesY;

  SelectionOverlayPainter({
    required this.selection,
    required this.handleSize,
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

    final rect = selection;
    if (rect == null) return;
    final border = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = handleSize / 6;
    canvas.drawRect(rect, border);

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

  @override
  bool shouldRepaint(SelectionOverlayPainter old) =>
      old.selection != selection ||
      old.handleSize != handleSize ||
      !listEquals(old.guidesX, guidesX) ||
      !listEquals(old.guidesY, guidesY);
}
