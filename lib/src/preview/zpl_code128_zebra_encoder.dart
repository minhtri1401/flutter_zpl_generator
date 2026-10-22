/// Code 128 encoder that reproduces Zebra's `^BC` automatic mode (`m = A`):
/// start in code set B, switch to code set C for digit runs of four or more
/// (encoding the first digit in B when the run is odd), and switch back when
/// the pairs run out. `package:barcode` never switches sets, so it prints
/// `ABC-12345` 11 modules wider than the printer does.
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

/// Symbols for ZPL mode N: no automatic switching. The start code comes from
/// a leading invocation, else subset B (ZPL II default). Other `>x`
/// sequences are plain characters. Throws [ArgumentError] when a character
/// does not exist in the chosen subset.
List<int> _modeNSymbols(String data) {
  final start = code128StartInvocation(data) ?? _startB;
  final cs = code128ModeNPayload(data).codeUnits;
  final bad = cs.indexWhere((c) => c > 0x7F);
  if (bad >= 0) {
    throw ArgumentError.value(
      data,
      'data',
      'Code 128 preview supports ASCII only',
    );
  }
  final out = <int>[start];
  switch (start) {
    case _startC:
      if (cs.length.isOdd || cs.any((c) => !_isDigit(c))) {
        throw ArgumentError.value(data, 'data', 'Subset C needs digit pairs');
      }
      for (int i = 0; i < cs.length; i += 2) {
        out.add((cs[i] - 0x30) * 10 + (cs[i + 1] - 0x30));
      }
    case _startA:
      for (final c in cs) {
        if (c >= 0x60) {
          throw ArgumentError.value(data, 'data', 'Not in subset A');
        }
        out.add(c < 0x20 ? c + 0x40 : c - 0x20);
      }
    default:
      for (final c in cs) {
        if (c < 0x20) {
          throw ArgumentError.value(data, 'data', 'Not in subset B');
        }
        out.add(c - 0x20);
      }
  }
  return out;
}

/// Symbol values (without check digit and stop) for [data]. With
/// [automatic] false this follows ZPL mode N (see [_modeNSymbols]).
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
List<double> zebraCode128Units(String data, {bool automatic = true}) {
  final symbols = zebraCode128Symbols(data, automatic: automatic);
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
