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
  modeDTests();
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
    List<int> n(String d) => zebraCode128Symbols(d, automatic: false);

    test('symbol vectors follow the printer (Labelary-verified)', () {
      const vectors = <String, List<int>>{
        'X001ABCDE1': [104, 56, 16, 16, 17, 33, 34, 35, 36, 37, 17],
        '>:X001ABCDE1': [104, 56, 16, 16, 17, 33, 34, 35, 36, 37, 17],
        '>9X001ABCDE1': [103, 0],
        '>9X0102': [103, 1, 2],
        '>9X0011': [103, 0, 11],
        '>956161617333435363717': [
          103, 56, 16, 16, 17, 33, 34, 35, 36, 37, 17, //
        ],
        '>;123456': [105, 12, 34, 56],
        '>;12345': [105, 12, 34],
        '>;12AB34': [105, 12, 34],
        '>:AB>70102': [104, 33, 34, 101, 1, 2],
        '>:AB>51234': [104, 33, 34, 99, 12, 34],
        '>90102>6AB': [103, 1, 2, 100, 33, 34],
        '>;1234>6AB': [105, 12, 34, 100, 33, 34],
        '>;1234>70102': [105, 12, 34, 101, 1, 2],
        '>:A><B>0C>=D': [104, 33, 62, 34, 30, 35, 94, 36],
        '>:A>1B': [104, 33, 95, 34],
        '>:>8AB': [104, 102, 33, 34],
        '>:A>6B': [104, 33, 100, 34],
        '>:AB>90102': [104, 33, 34, 16, 17, 16, 18],
        '>:AB>;1234': [104, 33, 34, 17, 18, 19, 20],
        '>:A>>B': [104, 33, 34],
        '>:A>AB': [104, 33, 34],
        '>:AB>': [104, 33, 34],
        '>8AB': [104, 102, 33, 34],
        '>70102': [104, 101, 1, 2],
        '>9>00102': [103, 30, 1, 2],
        '>:AB>82112': [104, 33, 34, 102, 18, 17, 17, 18],
        '>:A B': [104, 33, 0, 34],
      };
      vectors.forEach((input, expected) {
        expect(n(input), expected, reason: input);
      });
    });

    test('FNSKU module totals: digit-pair reading is 46, subset B is 145', () {
      double total(String d) => zebraCode128Units(
        d,
        automatic: false,
      ).fold<double>(0, (a, b) => a + b);
      expect(total('>9X001ABCDE1'), 46);
      expect(total('>:X001ABCDE1'), 145);
    });

    test('check digit is mod 103', () {
      // Start B (104), A (33), B (34): (104 + 33×1 + 34×2) mod 103 = 102.
      final s = n('>:AB');
      expect(s, [104, 33, 34]);
      final check = (104 + s[1] * 1 + s[2] * 2) % 103;
      expect(check, 102);
      final u = zebraCode128Units('>:AB', automatic: false);
      expect(u, hasLength((s.length + 2) * 6 + 1));
      expect(
        u,
        _packageUnits(
          Barcode.code128(useCode128A: false, useCode128C: false),
          'AB',
        ),
      );
    });

    test('code128UnitsOf matches zebraCode128Units', () {
      final s = n('>;123456');
      expect(
        code128UnitsOf(s),
        zebraCode128Units('>;123456', automatic: false),
      );
    });

    test('no invocation stays in subset B and is wider than automatic', () {
      final s = n('1234567890');
      expect(s.first, 104);
      expect(s, hasLength(11));
      final nw = zebraCode128Units(
        '1234567890',
        automatic: false,
      ).fold<double>(0, (a, b) => a + b);
      final aw = zebraCode128Units(
        '1234567890',
      ).fold<double>(0, (a, b) => a + b);
      expect(nw, greaterThan(aw));
    });

    test('start helpers', () {
      expect(code128StartInvocation('>'), isNull);
      expect(code128StartInvocation('>9X'), 103);
      expect(code128StartInvocation('>:X'), 104);
      expect(code128StartInvocation('>;X'), 105);
      expect(code128StartInvocation('>5X'), isNull);
      expect(code128ModeNPayload('>9X'), 'X');
      expect(code128ModeNPayload('X'), 'X');
    });

    test('an empty field is just the start symbol', () {
      expect(n(''), [104]);
      expect(n('>9'), [103]);
    });

    test('shift, pair 98 in set A and out-of-range characters throw', () {
      for (final d in ['>:A>4B', '>9019899', '>9>4', 'é', 'a\n', '>:\u0080']) {
        expect(() => n(d), throwsArgumentError, reason: d);
      }
    });

    test('pair 99 in set A is CODE C and switches the set', () {
      expect(n('>9990102'), [103, 99, 1, 2]);
    });

    test('DEL (0x7F) is a valid set B character', () {
      expect(n('>:\u007f'), [104, 95]);
    });

    test('interpretation text is the decoded data', () {
      expect(code128ModeNText('>93334353637'), 'ABCDE');
      expect(code128ModeNText('>:AB>51234'), 'AB1234');
      expect(code128ModeNText('>;123456'), '123456');
      expect(code128ModeNText('>9X001ABCDE1'), ' ');
      expect(code128ModeNText('X001ABCDE1'), 'X001ABCDE1');
      expect(code128ModeNText('>:A><B>1C'), 'A^BC');
      // ><, >0 and >= are data values (^, > and ~ in B), Labelary-verified.
      expect(code128ModeNText('>:A><B>0C>=D'), 'A^B>C~D');
      expect(code128ModeNText('>9>00102'), '>!"');
      // In set A, 94 is a control value and prints nothing; in C it is "94".
      expect(code128ModeNText('>9A>=B'), '');
      expect(code128ModeNText('>;>=12'), '9412');
      // Function values stay silent.
      expect(code128ModeNText('>:A>1B>2C>3D>8E'), 'ABCDE');
      expect(code128ModeNText('>9X'), '');
      // Set A values 64+ are control codes: no text.
      expect(code128ModeNText('>95364'), 'U');
      expect(code128ModeNText('>96470'), '');
    });

    test('automatic subset switching keeps working', () {
      expect(() => zebraCode128Symbols('é'), throwsArgumentError);
      expect(zebraCode128Symbols('\nA').first, 103);
      expect(zebraCode128Symbols('a\nb'), [104, 65, 101, 0x4A, 100, 66]);
    });

    test('automatic default is unchanged', () {
      expect(zebraCode128Symbols('12345'), [105, 12, 34, 100, 21]);
      expect(zebraCode128Symbols('>:AB'), [104, 30, 26, 33, 34]);
    });
  });
}

void modeDTests() {
  group('zebraGs1_128Symbols (mode D)', () {
    final vectors = <String, List<int>>{
      '(01)09501101530003(10)A1': [
        105,
        102,
        1,
        9,
        50,
        11,
        1,
        53,
        0,
        3,
        10,
        100,
        33,
        17,
      ],
      '(10)ABC(21)123': [105, 102, 10, 100, 33, 34, 35, 18, 99, 11, 23],
      '(01)0950110153000': [105, 102, 1, 9, 50, 11, 1, 53, 0, 100, 16],
      '(01)09501101530003(17)261231(10)A1': [
        105,
        102,
        1,
        9,
        50,
        11,
        1,
        53,
        0,
        3,
        17,
        26,
        12,
        31,
        10,
        100,
        33,
        17,
      ],
      '(10)12345': [105, 102, 10, 12, 34, 100, 21],
      '0109501101530003': [105, 102, 1, 9, 50, 11, 1, 53, 0, 3],
      '(01) 09501101530003': [105, 102, 1, 9, 50, 11, 1, 53, 0, 3],
      '(10)ab12': [105, 102, 10, 100, 65, 66, 17, 18],
      '(21)1234567(10)AB': [105, 102, 21, 12, 34, 56, 71, 100, 16, 33, 34],
      '(90)AB': [105, 102, 90, 100, 33, 34],
      '(240)AB': [105, 102, 24, 100, 16, 33, 34],
      '(90)12AB': [105, 102, 90, 12, 100, 33, 34],
      'AB': [104, 102, 33, 34],
      '(10)ABC>8(21)123': [
        105,
        102,
        10,
        100,
        33,
        34,
        35,
        99,
        102,
        21,
        12,
        100,
        19,
      ],
      '(10)ABC>8(21)A': [105, 102, 10, 100, 33, 34, 35, 99, 102, 21, 100, 33],
      '(10)ABC>8(240)A': [
        105,
        102,
        10,
        100,
        33,
        34,
        35,
        99,
        102,
        24,
        100,
        16,
        33,
      ],
      '(10)ABC>8(21)12': [105, 102, 10, 100, 33, 34, 35, 99, 102, 21, 12],
      '(10)ABC>8(21)1234': [105, 102, 10, 100, 33, 34, 35, 99, 102, 21, 12, 34],
      '(10)1234>8(21)56': [105, 102, 10, 12, 34, 102, 21, 56],
      '(10)123>8(21)56': [105, 102, 10, 12, 100, 19, 102, 99, 21, 56],
      '(10)AB3>8(21)12': [105, 102, 10, 100, 33, 34, 19, 102, 99, 21, 12],
      '(10)1234>8(21)AB': [105, 102, 10, 12, 34, 102, 21, 100, 33, 34],
      '(10)12345>8(21)12': [105, 102, 10, 12, 34, 100, 21, 102, 99, 21, 12],
      '(10)123>8(21)A': [105, 102, 10, 12, 100, 19, 102, 18, 17, 33],
      '(10)AB34>8(21)12': [105, 102, 10, 100, 33, 34, 99, 34, 102, 21, 12],
      '(10)AB>8(240)1': [105, 102, 10, 100, 33, 34, 99, 102, 24, 1],
    };
    var n = 0;
    for (final e in vectors.entries) {
      n++;
      test('D$n ${e.key}', () {
        expect(zebraGs1_128Symbols(e.key), e.value);
      });
    }

    test('178 modules for the 01 + 10 case', () {
      final units = code128UnitsOf(
        zebraGs1_128Symbols('(01)09501101530003(10)A1'),
      );
      expect(units.fold<double>(0, (a, b) => a + b), 178);
    });

    test('an FNC1 after a letter with no digits following stays in B', () {
      expect(zebraGs1_128Symbols('(10)AB>8CD'), [
        105,
        102,
        10,
        100,
        33,
        34,
        102,
        35,
        36,
      ]);
    });

    test('odd digit run followed by FNC1: digit, FNC1 in B, then CODE C', () {
      expect(zebraGs1_128Symbols('A1>82345'), [
        104,
        102,
        33,
        17,
        102,
        99,
        23,
        45,
      ]);
    });

    test('odd run: the single digit, then CODE C, with FNC1 later in C', () {
      expect(zebraGs1_128Symbols('A123>845'), [
        104,
        102,
        33,
        17,
        99,
        23,
        102,
        45,
      ]);
    });

    test('a trailing separator is an FNC1', () {
      expect(zebraGs1_128Symbols('AB>8'), [104, 102, 33, 34, 102]);
    });

    test('any other > is unencodable', () {
      expect(() => zebraGs1_128Symbols('(10)A>0B'), throwsArgumentError);
      expect(() => zebraGs1_128Symbols('(10)A>:B'), throwsArgumentError);
      expect(() => zebraGs1_128Symbols('(10)A>'), throwsArgumentError);
    });

    test('leading separators are dropped (Labelary: same bars)', () {
      final plain = zebraGs1_128Symbols('(10)ABC');
      expect(zebraGs1_128Symbols('>8(10)ABC'), plain);
      expect(zebraGs1_128Symbols('>8>8(10)ABC'), plain);
      expect(() => zebraGs1_128Symbols('>8'), throwsArgumentError);
    });

    test('empty and non-ASCII data are unencodable', () {
      expect(() => zebraGs1_128Symbols(''), throwsArgumentError);
      expect(() => zebraGs1_128Symbols('( )'), throwsArgumentError);
      expect(() => zebraGs1_128Symbols('(10)é'), throwsArgumentError);
      expect(() => zebraGs1_128Symbols('(10)\n'), throwsArgumentError);
    });
  });

  group('gs1_128LineText', () {
    test('drops the separators and keeps the rest as typed', () {
      expect(gs1_128LineText('(10)ABC>8(21)123'), '(10)ABC(21)123');
      expect(gs1_128LineText('(01)09501101530003'), '(01)09501101530003');
    });
  });
}
