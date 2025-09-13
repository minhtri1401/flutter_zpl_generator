/// Enum for horizontal alignment of elements within a layout container.
enum ZplAlignment { left, center, right }

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
