import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

/// Physical label stock sizes; dots depend on the printer density.
class LabelPreset {
  final String name;
  final double widthMm;
  final double heightMm;

  const LabelPreset(this.name, this.widthMm, this.heightMm);

  int widthDots(double dpmm) => (widthMm * dpmm).round();
  int heightDots(double dpmm) => (heightMm * dpmm).round();

  static const double _inch = 25.4;

  static const List<LabelPreset> all = [
    LabelPreset('4 x 6 in', 4 * _inch, 6 * _inch),
    LabelPreset('4 x 3 in', 4 * _inch, 3 * _inch),
    LabelPreset('4 x 2 in', 4 * _inch, 2 * _inch),
    LabelPreset('3 x 2 in', 3 * _inch, 2 * _inch),
    LabelPreset('2.25 x 1.25 in', 2.25 * _inch, 1.25 * _inch),
    LabelPreset('2 x 1 in', 2 * _inch, 1 * _inch),
    LabelPreset('100 x 150 mm', 100, 150),
    LabelPreset('100 x 100 mm', 100, 100),
    LabelPreset('80 x 50 mm', 80, 50),
    LabelPreset('60 x 40 mm', 60, 40),
    LabelPreset('50 x 30 mm', 50, 30),
    LabelPreset('40 x 30 mm', 40, 30),
  ];

  /// The preset whose dot size matches [width] x [height] at [dpmm], if any.
  static LabelPreset? matching(int width, int height, double dpmm) {
    for (final p in all) {
      if (p.widthDots(dpmm) == width && p.heightDots(dpmm) == height) return p;
    }
    return null;
  }
}

/// Display units for the inspector; ZPL itself always uses dots.
enum EditorUnits {
  dots('dots'),
  mm('mm'),
  inch('in');

  final String label;
  const EditorUnits(this.label);

  String format(int dots, double dpmm) => switch (this) {
        EditorUnits.dots => '$dots',
        EditorUnits.mm => '${(dots / dpmm).toStringAsFixed(1)} mm',
        EditorUnits.inch => '${(dots / dpmm / 25.4).toStringAsFixed(2)} in',
      };
}

/// Dots per millimetre for a density; 203 dpi (8 dpmm) when unset.
double dpmmFor(ZplPrintDensity? density) =>
    density == null ? 8 : density.dpi / 25.4;
