/// Enum for horizontal alignment of elements within a layout container.
enum ZplAlignment { left, center, right }

/// Enum for print density (resolution).
/// Corresponds to the `^JM` command.
enum ZplPrintDensity {
  normal('A', 203), // Defaulting normal to 203 DPI
  half('B', 101),
  d6('A', 152),
  d8('A', 203),
  d12('A', 300),
  d24('A', 600);

  const ZplPrintDensity(this.value, this.dpi);
  final String value;
  final int dpi;
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

/// Enum for print density options supported by the Labelary API.
enum LabelaryPrintDensity {
  d6('6dpmm'),
  d8('8dpmm'),
  d12('12dpmm'),
  d24('24dpmm');

  const LabelaryPrintDensity(this.value);
  final String value;
}

/// Enum for output formats supported by the Labelary API.
enum LabelaryOutputFormat {
  png('image/png'),
  pdf('application/pdf'),
  ipl('application/ipl'),
  epl('application/epl'),
  dpl('application/dpl'),
  zpl('application/zpl'),
  sbpl('application/sbpl'),
  pcl5('application/pcl5'),
  pcl6('application/pcl6'),
  json('application/json');

  const LabelaryOutputFormat(this.acceptHeader);
  final String acceptHeader;
}

/// Label rotation degrees supported by the Labelary API.
enum LabelaryRotation {
  rotate0(0),
  rotate90(90),
  rotate180(180),
  rotate270(270);

  const LabelaryRotation(this.degrees);
  final int degrees;
}

/// PDF page sizes supported by the Labelary API.
enum LabelaryPageSize {
  letter('Letter'),
  legal('Legal'),
  a4('A4'),
  a5('A5'),
  a6('A6');

  const LabelaryPageSize(this.value);
  final String value;
}

/// PDF page orientation supported by the Labelary API.
enum LabelaryPageOrientation {
  portrait('Portrait'),
  landscape('Landscape');

  const LabelaryPageOrientation(this.value);
  final String value;
}

/// PDF page alignment supported by the Labelary API.
enum LabelaryPageAlign {
  left('Left'),
  right('Right'),
  center('Center'),
  justify('Justify');

  const LabelaryPageAlign(this.value);
  final String value;
}

/// PDF label border styles supported by the Labelary API.
enum LabelaryLabelBorder {
  dashed('Dashed'),
  solid('Solid'),
  none('None');

  const LabelaryLabelBorder(this.value);
  final String value;
}

/// PNG image quality supported by the Labelary API.
enum LabelaryPrintQuality {
  grayscale('Grayscale'),
  bitonal('Bitonal');

  const LabelaryPrintQuality(this.value);
  final String value;
}

/// Enum for different types of separators
enum ZplSeparatorType {
  /// Use ZPL box drawing for solid lines
  box,

  /// Use repeated characters for decorative lines
  character,
}
