/// Enum for horizontal alignment of elements within a layout container.
enum ZplAlignment { left, center, right }

/// Enum for print density (resolution).
/// Corresponds to the `^JM` command for setting print density.
enum ZplPrintDensity {
  /// 6 dots per mm (152 DPI) - Standard resolution
  dpi152('A'),

  /// 8 dots per mm (203 DPI) - Most common resolution
  dpi203('B'),

  /// 12 dots per mm (300 DPI) - High resolution
  dpi300('C'),

  /// 24 dots per mm (600 DPI) - Very high resolution
  dpi600('D');

  const ZplPrintDensity(this.value);
  final String value;

  /// Get the DPI value for this density
  int get dpi {
    switch (this) {
      case ZplPrintDensity.dpi152:
        return 152;
      case ZplPrintDensity.dpi203:
        return 203;
      case ZplPrintDensity.dpi300:
        return 300;
      case ZplPrintDensity.dpi600:
        return 600;
    }
  }

  /// Get the dots per mm value for this density
  int get dotsPerMm {
    switch (this) {
      case ZplPrintDensity.dpi152:
        return 6;
      case ZplPrintDensity.dpi203:
        return 8;
      case ZplPrintDensity.dpi300:
        return 12;
      case ZplPrintDensity.dpi600:
        return 24;
    }
  }
}

/// Enum for ZPL fonts. Corresponds to the `^A` command.
/// zero is the scalable font.
enum ZplFont { a, b, c, d, e, f, g, h, zero }

/// Enum for field orientation.
enum ZplOrientation { normal, rotated90, inverted180, readFromBottomUp270 }

/// Enum for different barcode types.
enum ZplBarcodeType {
  /// Code 128 Barcode with subsets A, B, and C.
  code128,

  /// Code 39 Barcode
  code39,

  /// QR Code (2D barcode)
  qrCode,
  // More types can be added as needed
}

/// Enum for different print modes.
/// Corresponds to the `^MM` command.
enum ZplPrintMode { tearOff, peelOff, rewind, applicator, cutter }

/// Enum for media types.
/// Corresponds to the `^MT` command.
enum ZplMediaType { thermalTransfer, directThermal }

/// Enum for print orientation.
/// Corresponds to the `^PO` command.
enum ZplPrintOrientation { normal, inverted }

/// Enum for printer storage locations.
enum ZplStorage {
  /// DRAM (volatile memory) - faster but lost on power cycle
  dram('R:'),

  /// Flash memory (non-volatile) - persistent across power cycles
  flash('E:');

  const ZplStorage(this.path);
  final String path;
}
