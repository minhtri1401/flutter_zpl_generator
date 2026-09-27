import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/src/preview/zpl_barcode_symbol_metrics.dart';
import 'package:qr/qr.dart';

/// Expected version (module count), effective level and mask were recorded
/// from Labelary renders of `^BQN,2,3^FD<level>A,<data>` on 2026-09-27.
void main() {
  const url = 'https://pub.dev/packages/flutter_zpl_generator';
  const example = 'https://example.com/a/b/c?x=1&y=2';

  ({int modules, int level, int mask}) build(String data, int level) {
    final img = buildZebraStyleQr(data, level);
    return (
      modules: img.moduleCount,
      level: img.errorCorrectLevel,
      mask: img.maskPattern,
    );
  }

  test(
    'requested level is upgraded to the strongest that fits the version',
    () {
      expect(
        build('hello world', QrErrorCorrectLevel.L).level,
        QrErrorCorrectLevel.Q,
      );
      expect(
        build('hello world', QrErrorCorrectLevel.M).level,
        QrErrorCorrectLevel.Q,
      );
      expect(build(url, QrErrorCorrectLevel.M).level, QrErrorCorrectLevel.Q);
      expect(build(url, QrErrorCorrectLevel.L).level, QrErrorCorrectLevel.L);
      expect(
        build(example, QrErrorCorrectLevel.L).level,
        QrErrorCorrectLevel.M,
      );
      expect(
        build(example, QrErrorCorrectLevel.Q).level,
        QrErrorCorrectLevel.H,
      );
    },
  );

  test('module counts match Labelary', () {
    expect(build(url, QrErrorCorrectLevel.L).modules, 29);
    expect(build(url, QrErrorCorrectLevel.M).modules, 33);
    expect(build(url, QrErrorCorrectLevel.H).modules, 41);
    expect(build('hello world', QrErrorCorrectLevel.H).modules, 25);
    expect(build('HELLO WORLD 12345', QrErrorCorrectLevel.M).modules, 21);
  });
}
