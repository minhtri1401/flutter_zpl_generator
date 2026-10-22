/// QR Code error-correction level (`^BQ` and the `^FD` prefix).
///
/// Higher levels survive more damage at the cost of a larger symbol.
enum ZplQrErrorCorrection {
  /// ~7 % recovery — smallest symbol.
  low('L'),

  /// ~15 % recovery — Zebra's default.
  medium('M'),

  /// ~25 % recovery.
  quartile('Q'),

  /// ~30 % recovery — densest symbol.
  high('H');

  const ZplQrErrorCorrection(this.code);

  /// Single-letter code used in the `^FD<code>A,` prefix.
  final String code;
}

/// Code 128 input mode (`^BC` parameter `m`).
enum ZplCode128Mode {
  /// `A`: the printer picks the subsets itself. The default.
  automatic,

  /// `N`: no automatic subset switching. A leading `>9` (subset A), `>:`
  /// (subset B) or `>;` (subset C) start invocation in the data picks the
  /// starting subset; without one the symbol starts in subset B.
  none,
}
