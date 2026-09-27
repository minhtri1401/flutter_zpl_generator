import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

/// Faint dot grid every [step] dots to hint at snapping.
class GridOverlayPainter extends CustomPainter {
  final int step;

  GridOverlayPainter({required this.step});

  @override
  void paint(Canvas canvas, Size size) {
    if (step <= 0) return;
    final paint = Paint()..color = Colors.black12;
    final points = <Offset>[];
    for (double x = 0; x <= size.width; x += step) {
      for (double y = 0; y <= size.height; y += step) {
        points.add(Offset(x, y));
      }
    }
    canvas.drawPoints(PointMode.points, points, paint..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(GridOverlayPainter old) => old.step != step;
}
