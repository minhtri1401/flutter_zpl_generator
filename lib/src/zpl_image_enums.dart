/// Image-to-monochrome conversion strategy.
enum ZplDitheringAlgorithm {
  /// Simple thresholding: pixels with luminance < 128 become black.
  threshold,

  /// Floyd-Steinberg: error-diffusion producing smooth gradients.
  floydSteinberg,

  /// Atkinson: wider error-diffusion, crisper "newspaper print" dot patterns.
  atkinson,
}

/// Hex-body encoding strategy for `~DG` downloads and `^GFA` inline graphics.
enum ZplImageCompression {
  /// Raw ASCII hex (maximum compatibility; largest wire size).
  none,

  /// ACS run-length encoding (compact; supported by all Zebra printers).
  acs,

  /// `:B64:` — base64 of the raw bitmap with a CRC-16 trailer. Slightly
  /// smaller than hex (~33 % overhead vs 100 %). Requires firmware with
  /// B64/Z64 support (most printers since the mid‑2000s; all Link‑OS).
  b64,

  /// `:Z64:` — zlib-deflated bitmap, base64-encoded, CRC-16 trailer.
  /// Usually the smallest body (70–90 % reduction on logos). Same firmware
  /// requirement as [b64].
  z64,
}
