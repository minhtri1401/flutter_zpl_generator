import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/zpl_label_editor.dart';

void main() {
  test('presets convert to dots at 203 and 300 dpi', () {
    final fourBySix = LabelPreset.all.first;
    expect((fourBySix.widthDots(8), fourBySix.heightDots(8)), (813, 1219));
    final dpmm300 = dpmmFor(ZplPrintDensity.d12);
    expect(dpmm300, closeTo(11.81, 0.01));
    expect(fourBySix.widthDots(dpmm300), 1200);
  });

  test('matching finds the preset for a dot size, else null', () {
    expect(LabelPreset.matching(813, 1219, 8)?.name, '4 x 6 in');
    expect(LabelPreset.matching(800, 600, 8), isNull);
  });

  test('units format dots', () {
    expect(EditorUnits.dots.format(203, 8), '203');
    expect(EditorUnits.mm.format(203, 8), '25.4 mm');
    expect(EditorUnits.inch.format(203, 8), '1.00 in');
  });

  test('controller exposes dpmm, units and formatting', () {
    final c = EditorController(
      document: const LabelDocument(config: ZplConfiguration(printDensity: ZplPrintDensity.d12)),
    );
    expect(c.dpmm, closeTo(11.81, 0.01));
    var notified = 0;
    c.addListener(() => notified++);
    c.units = EditorUnits.mm;
    c.units = EditorUnits.mm;
    expect(notified, 1);
    expect(c.formatDots(118), '10.0 mm');
  });
}
