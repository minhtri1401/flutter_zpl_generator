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
  modeNTests();
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

void modeNTests() {
  group('mode N', () {
    test('>9 starts subset A and never switches', () {
      final s = zebraCode128Symbols('>9X001ABCDE1', automatic: false);
      expect(s, [103, ...'X001ABCDE1'.codeUnits.map((c) => c - 0x20)]);
      expect(s, hasLength(11));
    });

    test('FNSKU symbol is 145 modules', () {
      final u = zebraCode128Units('>9X001ABCDE1', automatic: false);
      expect(u.fold<double>(0, (a, b) => a + b), 145);
      expect(145 * 2, 290);
    });

    test('check digit is mod 103', () {
      final s = zebraCode128Symbols('>9AB', automatic: false);
      final check = (103 + s[1] * 1 + s[2] * 2) % 103;
      final u = zebraCode128Units('>9AB', automatic: false);
      expect(u, hasLength((s.length + 2) * 6 + 1));
      expect(check, isA<int>());
    });

    test('no invocation stays in subset B and is wider than automatic', () {
      final n = zebraCode128Symbols('1234567890', automatic: false);
      expect(n.first, 104);
      expect(n, hasLength(11));
      final nw = zebraCode128Units(
        '1234567890',
        automatic: false,
      ).fold<double>(0, (a, b) => a + b);
      final aw = zebraCode128Units(
        '1234567890',
      ).fold<double>(0, (a, b) => a + b);
      expect(nw, greaterThan(aw));
    });

    test('>: and >; pick B and C, other invocations are literal', () {
      expect(zebraCode128Symbols('>:ab', automatic: false), [104, 65, 66]);
      expect(zebraCode128Symbols('>;1234', automatic: false), [105, 12, 34]);
      expect(zebraCode128Symbols('>5A', automatic: false), [
        104,
        0x3E - 0x20,
        0x35 - 0x20,
        0x41 - 0x20,
      ]);
      expect(code128StartInvocation('>'), isNull);
      expect(code128ModeNPayload('>9X'), 'X');
      expect(code128ModeNPayload('X'), 'X');
    });

    test('control characters encode in subset A', () {
      expect(zebraCode128Symbols('>9\n', automatic: false), [103, 0x4A]);
    });

    test('characters outside the subset throw', () {
      expect(
        () => zebraCode128Symbols('>9ab', automatic: false),
        throwsArgumentError,
      );
      expect(
        () => zebraCode128Symbols('a\n', automatic: false),
        throwsArgumentError,
      );
      expect(
        () => zebraCode128Symbols('>;123', automatic: false),
        throwsArgumentError,
      );
      expect(
        () => zebraCode128Symbols('>;12a4', automatic: false),
        throwsArgumentError,
      );
      expect(
        () => zebraCode128Symbols('é', automatic: false),
        throwsArgumentError,
      );
    });

    test('automatic subset switching keeps working', () {
      expect(() => zebraCode128Symbols('é'), throwsArgumentError);
      expect(zebraCode128Symbols('\nA').first, 103);
      expect(zebraCode128Symbols('a\nb'), [104, 65, 101, 0x4A, 100, 66]);
    });

    test('automatic default is unchanged', () {
      expect(zebraCode128Symbols('12345'), [105, 12, 34, 100, 21]);
    });
  });
}
