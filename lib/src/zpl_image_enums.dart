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
}
