import 'package:flutter/material.dart';

import '../model/label_preset.dart';

/// Tick marks along the label's top and left edges in mm or inches.
/// [zoom] keeps tick lengths and labels a constant on-screen size.
class RulerOverlayPainter extends CustomPainter {
  final double dpmm;
  final EditorUnits units;
  final double zoom;

  RulerOverlayPainter({
    required this.dpmm,
    required this.units,
    required this.zoom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (units == EditorUnits.dots) return;
    // Minor/major tick spacing in dots.
    final minor = units == EditorUnits.mm ? dpmm : dpmm * 25.4 / 8;
    final majorEvery = units == EditorUnits.mm ? 10 : 8;
    final paint = Paint()
      ..color = Colors.blueGrey.withValues(alpha: 0.6)
      ..strokeWidth = 1 / zoom;
    final long = 10 / zoom;
    final short = 5 / zoom;
    final style = TextStyle(color: Colors.blueGrey, fontSize: 9 / zoom);

    for (var i = 0; i * minor <= size.width; i++) {
      final x = i * minor;
      final major = i % majorEvery == 0;
      canvas.drawLine(Offset(x, 0), Offset(x, major ? long : short), paint);
      if (major && i > 0) {
        _label(canvas, '${i ~/ majorEvery}', Offset(x + 2 / zoom, long), style);
      }
    }
    for (var i = 0; i * minor <= size.height; i++) {
      final y = i * minor;
      final major = i % majorEvery == 0;
      canvas.drawLine(Offset(0, y), Offset(major ? long : short, y), paint);
      if (major && i > 0) {
        _label(canvas, '${i ~/ majorEvery}', Offset(long, y + 2 / zoom), style);
      }
    }
  }

  void _label(Canvas canvas, String text, Offset at, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, at);
  }

  @override
  bool shouldRepaint(RulerOverlayPainter old) =>
      old.dpmm != dpmm || old.units != units || old.zoom != zoom;
}
