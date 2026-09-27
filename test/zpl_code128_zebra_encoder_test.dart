import 'package:barcode/barcode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/src/preview/zpl_code128_zebra_encoder.dart';

/// Module widths of every bar/space `package:barcode` emits for [data].
List<double> _packageUnits(Barcode bc, String data) {
  final bars = bc
      .make(data, width: 4096, height: 10)
      .whereType<BarcodeBar>()
      .toList();
  final module = bars.map((e) => e.width).reduce((a, b) => a < b ? a : b);
  return [for (final b in bars) (b.width / module).roundToDouble()];
}

void main() {
  test(
    'code set B symbols match the reference encoder (values 0–94, 104, 106)',
    () {
      // Every set-B character, with digits interleaved so no run reaches
      // four (a longer run would legitimately switch to set C).
      final printable = String.fromCharCodes([
        for (int c = 0x20; c < 0x30; c++) c,
        for (int c = 0x30; c < 0x3A; c++) ...[c, 0x41 + (c - 0x30)],
        for (int c = 0x3A; c < 0x7F; c++) c,
      ]);
      final ref = _packageUnits(
        Barcode.code128(useCode128A: false, useCode128C: false),
        printable,
      );
      final mine = zebraCode128Units(printable);
      final firstDiff = List.generate(
        mine.length < ref.length ? mine.length : ref.length,
        (i) => i,
      ).where((i) => mine[i] != ref[i]).firstOrNull;
      expect(
        mine,
        ref,
        reason:
            'lengths ${mine.length}/${ref.length}; first diff at element '
            '$firstDiff (symbol ${firstDiff == null ? '-' : firstDiff ~/ 6})',
      );
    },
  );

  test('code set C symbols match the reference encoder (values 0–99, 105)', () {
    final digits = List.generate(
      100,
      (i) => i.toString().padLeft(2, '0'),
    ).join();
    final ref = _packageUnits(
      Barcode.code128(useCode128A: false, useCode128B: false),
      digits,
    );
    expect(zebraCode128Units(digits), ref);
  });

  test('ABC-12345 packs the digit tail in set C like Zebra (123 modules)', () {
    final units = zebraCode128Units('ABC-12345');
    expect(units.fold<double>(0, (s, u) => s + u), 123);
    expect(zebraCode128Symbols('ABC-12345'), [
      104,
      33,
      34,
      35,
      13,
      17,
      99,
      23,
      45,
    ]);
  });

  test('even digit run switches straight to set C', () {
    expect(zebraCode128Symbols('AB1234'), [104, 33, 34, 99, 12, 34]);
  });

  test('all-digit even data starts in set C', () {
    expect(zebraCode128Symbols('123456'), [105, 12, 34, 56]);
  });

  test(
    'leading odd digit run starts in C and drops to B for the last digit',
    () {
      expect(zebraCode128Symbols('12345'), [105, 12, 34, 100, 21]);
    },
  );

  test('short digit runs stay in set B', () {
    expect(zebraCode128Symbols('A12B'), [104, 33, 17, 18, 34]);
  });
}
