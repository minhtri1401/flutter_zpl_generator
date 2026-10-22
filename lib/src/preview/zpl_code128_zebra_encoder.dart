/// Code 128 encoder that reproduces Zebra's `^BC` automatic mode (`m = A`):
/// start in code set B, switch to code set C for digit runs of four or more
/// (encoding the first digit in B when the run is odd), and switch back when
/// the pairs run out. `package:barcode` never switches sets, so it prints
/// `ABC-12345` 11 modules wider than the printer does.
///
/// Mode N (`^BC…,N`) follows the printer's invocation rules instead: see
/// [zebraCode128Symbols].
///
/// Output is the bar/space widths in modules (first element is a bar).
library;

/// Element widths for symbol values 0–106 (ISO/IEC 15417 Table 1).
/// Values 103–105 are Start A/B/C; 106 is Stop (7 elements).
const List<String> _patterns = [
  '212222',
  '222122',
  '222221',
  '121223',
  '121322',
  '131222',
  '122213',
  '122312',
  '132212',
  '221213',
  '221312',
  '231212',
  '112232',
  '122132',
  '122231',
  '113222',
  '123122',
  '123221',
  '223211',
  '221132',
  '221231',
  '213212',
  '223112',
  '312131',
  '311222',
  '321122',
  '321221',
  '312212',
  '322112',
  '322211',
  '212123',
  '212321',
  '232121',
  '111323',
  '131123',
  '131321',
  '112313',
  '132113',
  '132311',
  '211313',
  '231113',
  '231311',
  '112133',
  '112331',
  '132131',
  '113123',
  '113321',
  '133121',
  '313121',
  '211331',
  '231131',
  '213113',
  '213311',
  '213131',
  '311123',
  '311321',
  '331121',
  '312113',
  '312311',
  '332111',
  '314111',
  '221411',
  '431111',
  '111224',
  '111422',
  '121124',
  '121421',
  '141122',
  '141221',
  '112214',
  '112412',
  '122114',
  '122411',
  '142112',
  '142211',
  '241211',
  '221114',
  '413111',
  '241112',
  '134111',
  '111242',
  '121142',
  '121241',
  '114212',
  '124112',
  '124211',
  '411212',
  '421112',
  '421211',
  '212141',
  '214121',
  '412121',
  '111143',
  '111341',
  '131141',
  '114113',
  '114311',
  '411113',
  '411311',
  '113141',
  '114131',
  '311141',
  '411131',
  '211412',
  '211214',
  '211232',
  '2331112',
];

const int _codeC = 99, _codeB = 100, _codeA = 101;
const int _startA = 103, _startB = 104, _startC = 105, _stop = 106;

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

/// Start invocation at the head of mode-N data: `>9` (A), `>:` (B), `>;` (C).
/// Returns the start symbol value, or null when [data] has no invocation.
int? code128StartInvocation(String data) {
  if (data.length < 2 || data[0] != '>') return null;
  return switch (data[1]) {
    '9' => _startA,
    ':' => _startB,
    ';' => _startC,
    _ => null,
  };
}

/// The data a mode-N symbol encodes: [data] without a leading start
/// invocation. The interpretation line shows this text.
String code128ModeNPayload(String data) =>
    code128StartInvocation(data) == null ? data : data.substring(2);

/// Invocation values for `>x` sequences that emit one symbol and keep the
/// current set. `>5`, `>6` and `>7` also switch the set and are handled
/// separately. `><` (62), `>0` (30) and `>=` (94) are ordinary data values
/// (in set B `^`, `>` and `~`); the others are function values.
const Map<String, int> _invocationValues = {
  '<': 62,
  '0': 30,
  '=': 94,
  '1': 95,
  '2': 96,
  '3': 97,
  '8': 102,
};

/// Invocations whose value is data, so the interpretation line shows it.
const Set<String> _dataInvocations = {'<', '0', '='};

/// One walk over mode-N data: the symbol values (without check digit and
/// stop) and the text the interpretation line shows.
///
/// These are the rules the printer follows, verified against Labelary:
///
/// * A leading `>9` (Start A), `>:` (Start B) or `>;` (Start C) picks the
///   start symbol. Without one the symbol starts in B and nothing is
///   consumed.
/// * Input form depends on the current set. Sets A and C read digit pairs
///   (`00`-`99`, each pair is one symbol value): a non-digit, a digit whose
///   next character is not a digit and a trailing lone digit are skipped.
///   Set B reads ASCII (value = character - 0x20).
/// * `>` always starts an invocation, even while reading pairs. `><`, `>0`,
///   `>=`, `>1`, `>2`, `>3` and `>8` emit fixed values (the first three are
///   data values and print, the rest are function values); `>5` emits CODE C,
///   `>6` CODE B and `>7` CODE A and switch the set. A later `>9`, `>:` or
///   `>;`, an unknown `>x` and a trailing `>` are dropped.
/// * `>4` (SHIFT), pair 98 in set A and a set-B character outside
///   0x20-0x7F cannot be encoded: [ArgumentError].
/// * Pair 99 in set A is CODE C: it is emitted and the set becomes C.
({List<int> symbols, String text}) _modeNWalk(String data) {
  final start = code128StartInvocation(data);
  final cs = data.codeUnits;
  final out = <int>[start ?? _startB];
  final text = StringBuffer();
  // 'A', 'B' or 'C'.
  String set = switch (start) {
    _startA => 'A',
    _startC => 'C',
    _ => 'B',
  };
  // The printed character of symbol value [v] in the current set, if any:
  // set B values are characters, set A values 0-63 are 0x20-0x5F (higher
  // values are controls), set C values are two digits.
  void writeValue(int v) {
    if (set == 'C') {
      text.write(v.toString().padLeft(2, '0'));
    } else if (set == 'B' ? v < 95 : v < 64) {
      text.writeCharCode(v + 0x20);
    }
  }

  int i = start == null ? 0 : 2;
  while (i < cs.length) {
    final c = cs[i];
    if (c == 0x3E) {
      if (i + 1 >= cs.length) break; // trailing '>' is dropped
      final x = data[i + 1];
      i += 2;
      final fixed = _invocationValues[x];
      if (fixed != null) {
        out.add(fixed);
        if (_dataInvocations.contains(x)) writeValue(fixed);
      } else if (x == '5') {
        out.add(_codeC);
        set = 'C';
      } else if (x == '6') {
        out.add(_codeB);
        set = 'B';
      } else if (x == '7') {
        out.add(_codeA);
        set = 'A';
      } else if (x == '4') {
        throw ArgumentError.value(data, 'data', 'SHIFT (>4) is not supported');
      }
      // '>9', '>:', '>;' after the start and unknown '>x' are dropped.
      continue;
    }
    if (set == 'B') {
      if (c < 0x20 || c > 0x7F) {
        throw ArgumentError.value(data, 'data', 'Not in subset B');
      }
      out.add(c - 0x20);
      text.writeCharCode(c);
      i++;
      continue;
    }
    // Sets A and C read digit pairs.
    if (!_isDigit(c) || i + 1 >= cs.length || !_isDigit(cs[i + 1])) {
      i++;
      continue;
    }
    final v = (c - 0x30) * 10 + (cs[i + 1] - 0x30);
    i += 2;
    out.add(v);
    if (set == 'A' && v == 98) {
      throw ArgumentError.value(data, 'data', 'Pair 98 is SHIFT in subset A');
    }
    writeValue(v);
    if (set == 'A' && v == 99) set = 'C';
  }
  return (symbols: out, text: text.toString());
}

/// Symbols for ZPL mode N (see [_modeNWalk] for the rules).
List<int> _modeNSymbols(String data) => _modeNWalk(data).symbols;

/// The interpretation-line text of mode-N [data]: the decoded text of the
/// data symbols. Set B values are characters, set A values 0-63 are the
/// characters 0x20-0x5F (control values print nothing), set C values are
/// two digits, and function values print nothing. For `>93334353637` this
/// is `ABCDE`. Throws [ArgumentError] for data the printer cannot encode.
String code128ModeNText(String data) => _modeNWalk(data).text;

/// Symbol values (without check digit and stop) for [data]. With
/// [automatic] false this follows ZPL mode N: `>9`, `>;`, `>5` and `>7`
/// switch to a set that reads digit pairs (not ASCII), the other
/// invocations have fixed values (see `_modeNWalk`).
List<int> zebraCode128Symbols(String data, {bool automatic = true}) {
  if (!automatic) return _modeNSymbols(data);
  final cs = data.codeUnits;
  final bad = cs.indexWhere((c) => c > 0x7F);
  if (bad >= 0) {
    throw ArgumentError.value(
      data,
      'data',
      'Code 128 preview supports ASCII only (char ${cs[bad]} at $bad)',
    );
  }
  int digitRun(int i) {
    int n = 0;
    while (i + n < cs.length && _isDigit(cs[i + n])) {
      n++;
    }
    return n;
  }

  final out = <int>[];
  int i = 0;
  String set;
  // Zebra starts in C for a leading run of four or more digits even when
  // the run is odd; the last digit is then emitted after a Code B switch
  // (verified against Labelary: "12345" → Start C, 12, 34, Code B, 5).
  if (digitRun(0) >= 4) {
    out.add(_startC);
    set = 'C';
  } else if (cs.isNotEmpty && cs[0] < 0x20) {
    out.add(_startA);
    set = 'A';
  } else {
    out.add(_startB);
    set = 'B';
  }

  while (i < cs.length) {
    final run = digitRun(i);
    if (set == 'C') {
      if (run >= 2) {
        out.add((cs[i] - 0x30) * 10 + (cs[i + 1] - 0x30));
        i += 2;
        continue;
      }
      out.add(cs[i] < 0x20 ? _codeA : _codeB);
      set = cs[i] < 0x20 ? 'A' : 'B';
      continue;
    }
    if (run >= 4) {
      if (run.isOdd) {
        // Zebra: one digit in the current set, then the even tail in C.
        out.add(cs[i] - 0x20);
        i++;
      }
      out.add(_codeC);
      set = 'C';
      continue;
    }
    final c = cs[i];
    if (set == 'B' && c < 0x20) {
      out.add(_codeA);
      set = 'A';
    } else if (set == 'A' && c >= 0x60) {
      out.add(_codeB);
      set = 'B';
    }
    out.add(set == 'A' && c < 0x20 ? c + 0x40 : c - 0x20);
    i++;
  }
  return out;
}

/// Bar/space widths in modules for [data], including check digit and stop.
/// Elements alternate bar, space, bar, … and end with the stop's final bar.
List<double> zebraCode128Units(String data, {bool automatic = true}) =>
    code128UnitsOf(zebraCode128Symbols(data, automatic: automatic));

/// Bar/space widths in modules for [symbols] (values without check digit
/// and stop): the symbols, the mod-103 check digit and the stop pattern.
List<double> code128UnitsOf(List<int> symbols) {
  int check = symbols.first;
  for (int i = 1; i < symbols.length; i++) {
    check += symbols[i] * i;
  }
  final all = [...symbols, check % 103, _stop];
  return [
    for (final v in all)
      for (final ch in _patterns[v].codeUnits) (ch - 0x30).toDouble(),
  ];
}
