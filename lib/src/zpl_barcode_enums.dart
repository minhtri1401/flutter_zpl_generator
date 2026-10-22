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

  /// `N`: no automatic subset switching; the data carries `>` invocations.
  /// A leading `>9` (Start A), `>:` (Start B) or `>;` (Start C) picks the
  /// start; without one the symbol starts in subset B. Subsets A and C read
  /// **digit pairs** (`00`-`99`, one symbol each; other characters are
  /// skipped), not ASCII text, so `>9X001ABCDE1` prints a single symbol.
  /// Subset B reads ASCII. `>5`, `>6` and `>7` switch to C, B and A; `><`,
  /// `>0`, `>=`, `>1`, `>2`, `>3` and `>8` emit fixed function values.
  /// The interpretation line shows the decoded text.
  none,
}
