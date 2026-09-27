import 'dart:math' as math;

import 'package:barcode/barcode.dart';
import 'package:qr/qr.dart';

import '../enums.dart';
import '../zpl_barcode.dart';
import '../zpl_barcode_enums.dart';
import 'zpl_barcode_preview_mapping.dart';
import 'zpl_code128_zebra_encoder.dart';

/// Zebra's default `^BY` wide-to-narrow ratio for two-width symbologies
/// (Code 39, Interleaved 2 of 5).
const double zplDefaultWideNarrowRatio = 3.0;

final _digits = RegExp(r'^[0-9]+$');
final _alphaNum = RegExp(r'^[-0-9A-Z $%*+./:]+$');

/// Encodes [data] the way Zebra's automatic input mode does: numeric mode
/// for all-digit data, alphanumeric mode when every character is in the QR
/// alphanumeric set, byte mode otherwise, at the smallest version that fits.
/// (`QrCode.fromData` always uses byte mode, which picks a larger version
/// than the printer for short uppercase/numeric payloads.)
///
/// Zebra then raises the error-correction level to the strongest one that
/// still fits in that version (verified against Labelary: "hello world" at
/// L/M/Q all render the same Q symbol; the 46-char URL at M renders as Q).
QrImage buildZebraStyleQr(String data, int errorCorrectLevel) {
  QrImage? tryBuild(int version, int level) {
    final code = QrCode(version, level);
    if (_digits.hasMatch(data)) {
      code.addNumeric(data);
    } else if (_alphaNum.hasMatch(data)) {
      code.addAlphaNumeric(data);
    } else {
      code.addData(data);
    }
    try {
      // Building the image encodes the data; too much data for this
      // version throws.
      return QrImage(code);
    } on InputTooLongException {
      return null;
    }
  }

  for (int version = 1; version <= 40; version++) {
    final requested = tryBuild(version, errorCorrectLevel);
    if (requested == null) continue;
    for (final stronger in const [
      QrErrorCorrectLevel.H,
      QrErrorCorrectLevel.Q,
      QrErrorCorrectLevel.M,
    ]) {
      if (stronger == errorCorrectLevel) break;
      final upgraded = tryBuild(version, stronger);
      if (upgraded != null) return upgraded;
    }
    return requested;
  }
  throw ArgumentError('QR data too long: ${data.length} characters');
}

/// Printed size of a barcode symbol in dots, derived from the real encoded
/// module count rather than a per-character estimate. Excludes quiet zones
/// (Zebra does not print them) and the interpretation line.
class ZplBarcodeSymbolMetrics {
  /// 1D: width in modules of each bar/space, left to right, after applying
  /// the wide/narrow ratio. Empty for 2D symbologies.
  final List<double> barUnits;

  /// 2D: modules across / down. For 1D, `modulesWide` is the sum of
  /// [barUnits] and `modulesHigh` is 1.
  final double modulesWide;
  final int modulesHigh;

  /// Dots per module horizontally (`^BY` module width, QR/Aztec magnification).
  final double moduleWidth;

  /// Dots per module vertically (1D: bar height; DM/QR/Aztec: same as
  /// [moduleWidth]; PDF417: row height).
  final double moduleHeight;

  /// QR only: dark-module lookup for the fixed-mask symbol.
  final bool Function(int row, int col)? qrIsDark;

  const ZplBarcodeSymbolMetrics({
    required this.barUnits,
    required this.modulesWide,
    required this.modulesHigh,
    required this.moduleWidth,
    required this.moduleHeight,
    this.qrIsDark,
  });

  double get width => modulesWide * moduleWidth;
  double get height => modulesHigh * moduleHeight;
}

/// Probe size used to count modules: large enough that rounding is exact.
const double _probe = 4096;

/// Metrics are immutable per [ZplBarcode] (all fields are final), so cache
/// them: the painter asks 2–3 times per paint and long QR payloads take
/// ~1.5 ms to encode.
final _cache = Expando<ZplBarcodeSymbolMetrics>('zplBarcodeSymbolMetrics');

/// Measures [b]. Returns null when the data is not encodable in that
/// symbology (odd-length ITF, bad check digit, non-Latin Code 128, …).
ZplBarcodeSymbolMetrics? measureBarcodeSymbol(ZplBarcode b) {
  final cached = _cache[b];
  if (cached != null) return cached;
  final m = _measure(b);
  if (m != null) _cache[b] = m;
  return m;
}

ZplBarcodeSymbolMetrics? _measure(ZplBarcode b) {
  try {
    if (b.type == ZplBarcodeType.qrCode) return _measureQr(b);
    if (b.type == ZplBarcodeType.code128) return _measureCode128(b);
    final bars = previewBarcodeFor(b)
        .make(b.data, width: _probe, height: _probe)
        .whereType<BarcodeBar>()
        .toList();
    if (bars.isEmpty) return null;
    return isTwoDimensional(b.type) ? _measure2D(b, bars) : _measure1D(b, bars);
  } on Exception {
    return null; // BarcodeException, InputTooLongException: unencodable data
  } on ArgumentError {
    return null; // our own encoders reject data the symbology cannot carry
  }
}

ZplBarcodeSymbolMetrics _measureCode128(ZplBarcode b) {
  final units = zebraCode128Units(b.data);
  return ZplBarcodeSymbolMetrics(
    barUnits: units,
    modulesWide: units.fold(0, (s, u) => s + u),
    modulesHigh: 1,
    moduleWidth: (b.moduleWidth ?? 2).toDouble(),
    moduleHeight: b.height.toDouble(),
  );
}

ZplBarcodeSymbolMetrics _measure1D(ZplBarcode b, List<BarcodeBar> bars) {
  final module = bars.map((e) => e.width).reduce((a, c) => a < c ? a : c);
  final ratioBased =
      b.type == ZplBarcodeType.code39 ||
      b.type == ZplBarcodeType.interleaved2of5;
  final ratio = b.wideBarToNarrowBarRatio ?? zplDefaultWideNarrowRatio;
  // package:barcode ends some symbologies (Code 39, I 2 of 5) with an
  // inter-character space; the printer does not ink it, so drop it.
  while (bars.isNotEmpty && !bars.last.black) {
    bars.removeLast();
  }
  final units = <double>[];
  for (final bar in bars) {
    final u = (bar.width / module).round();
    // package:barcode encodes wide elements as 2 modules; Zebra prints them
    // at the ^BY ratio (default 3.0).
    units.add(ratioBased && u == 2 ? ratio : u.toDouble());
  }
  return ZplBarcodeSymbolMetrics(
    barUnits: units,
    modulesWide: units.fold(0, (s, u) => s + u),
    modulesHigh: 1,
    moduleWidth: (b.moduleWidth ?? 2).toDouble(),
    moduleHeight: b.height.toDouble(),
  );
}

/// PDF417 geometry from the `^B7` parameters. `package:barcode` picks its
/// own column/row split from the requested aspect ratio, so the printed
/// size is derived from the ZPL parameters instead: 17 modules per data
/// column plus start/stop/row-indicator columns (69), rows = codewords /
/// columns. Codeword count is estimated from the payload (text compaction
/// ~0.6 codeword per character, numeric ~0.35, plus the length descriptor)
/// and the error-correction codewords 2^(s+1). Verified on Labelary:
/// "Stacked 2D payload" at c=4, s=2 → 5 rows; auto columns, s=0 → 1 x 14.
ZplBarcodeSymbolMetrics _measurePdf417(ZplBarcode b) {
  final len = b.data.length;
  final numeric = RegExp(r'^[0-9]+$').hasMatch(b.data);
  final dataCodewords = (len * (numeric ? 0.35 : 0.6)).ceil() + 1;
  final total = dataCodewords + (1 << (b.pdf417SecurityLevel + 1));
  final cols = b.pdf417Columns ?? (math.sqrt(total) / 3).round().clamp(1, 30);
  final rows = (total / cols).ceil().clamp(3, 90);
  return ZplBarcodeSymbolMetrics(
    barUnits: const [],
    modulesWide: (17 * cols + 69).toDouble(),
    modulesHigh: rows,
    moduleWidth: (b.moduleWidth ?? 2).toDouble(),
    moduleHeight: b.height.toDouble(),
  );
}

ZplBarcodeSymbolMetrics _measure2D(ZplBarcode b, List<BarcodeBar> bars) {
  if (b.type == ZplBarcodeType.pdf417) return _measurePdf417(b);
  final mx = bars.map((e) => e.width).reduce((a, c) => a < c ? a : c);
  final my = bars.map((e) => e.height).reduce((a, c) => a < c ? a : c);
  final mw = (b.moduleWidth ?? 2).toDouble();
  final (dotsX, dotsY) = switch (b.type) {
    ZplBarcodeType.aztec => (
      b.magnification.toDouble(),
      b.magnification.toDouble(),
    ),
    // ^BX h = module height; modules are square.
    ZplBarcodeType.dataMatrix => (b.height.toDouble(), b.height.toDouble()),
    // ^B7: ^BY module width across, h = row height down.
    _ => (mw, b.height.toDouble()),
  };
  return ZplBarcodeSymbolMetrics(
    barUnits: const [],
    modulesWide: (_probe / mx).roundToDouble(),
    modulesHigh: (_probe / my).round(),
    moduleWidth: dotsX,
    moduleHeight: dotsY,
  );
}

ZplBarcodeSymbolMetrics _measureQr(ZplBarcode b) {
  final level = switch (b.qrErrorCorrection) {
    ZplQrErrorCorrection.low => QrErrorCorrectLevel.L,
    ZplQrErrorCorrection.medium => QrErrorCorrectLevel.M,
    ZplQrErrorCorrection.quartile => QrErrorCorrectLevel.Q,
    ZplQrErrorCorrection.high => QrErrorCorrectLevel.H,
  };
  // Mask selection: Labelary/Zebra pick a mask by their own scoring, which
  // no ISO/ZXing penalty variant reproduces. The package's choice matches
  // for some payloads; when it doesn't, the symbol is still the same size,
  // version and level — only the module pattern differs.
  final image = buildZebraStyleQr(b.data, level);
  final mag = b.magnification.toDouble();
  return ZplBarcodeSymbolMetrics(
    barUnits: const [],
    modulesWide: image.moduleCount.toDouble(),
    modulesHigh: image.moduleCount,
    moduleWidth: mag,
    moduleHeight: mag,
    qrIsDark: image.isDark,
  );
}
