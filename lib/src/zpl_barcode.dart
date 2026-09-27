import 'enums.dart';
import 'zpl_barcode_enums.dart';
import 'zpl_barcode_symbology_emitter.dart';
import 'zpl_barcode_width_estimator.dart';
import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// A barcode field. Symbology-specific ZPL lives in
/// `zpl_barcode_symbology_emitter.dart`; width estimates in
/// `zpl_barcode_width_estimator.dart`.
///
/// Supported: Code 128, GS1-128, Code 39, Code 93, Interleaved 2 of 5,
/// EAN-13, EAN-8, UPC-A, UPC-E, QR Code, Data Matrix, PDF417, Aztec.
class ZplBarcode extends ZplCommand {
  /// The x-axis position of the barcode.
  final int x;

  /// The y-axis position of the barcode.
  final int y;

  /// The data to be encoded in the barcode.
  final String data;

  /// The symbology. Defaults to Code 128.
  final ZplBarcodeType type;

  /// Bar height in dots for 1D codes; module/row height for Data Matrix
  /// and PDF417. Ignored by QR and Aztec (see [magnification]).
  final int height;

  /// The orientation of the barcode. Defaults to normal.
  final ZplOrientation orientation;

  /// Whether to print the human-readable interpretation line below the barcode.
  final bool printInterpretationLine;

  /// Whether to print the interpretation line above the barcode instead of below.
  final bool printInterpretationLineAbove;

  /// The module width (width of the narrowest bar) in dots. A value between 1 and 10.
  final int? moduleWidth;

  /// The wide bar to narrow bar width ratio. A value between 2.0 and 3.0.
  final double? wideBarToNarrowBarRatio;

  /// The horizontal alignment of the barcode. If null, uses manual positioning.
  final ZplAlignment? alignment;

  /// Maximum width constraint (set by layout containers like ZplGridRow).
  final int? maxWidth;

  /// Module size (1–10) for QR Code and Aztec. Defaults to 3.
  final int magnification;

  /// QR Code error-correction level. Defaults to [ZplQrErrorCorrection.medium].
  final ZplQrErrorCorrection qrErrorCorrection;

  /// PDF417 security (error-correction) level 0–8. Defaults to 0.
  final int pdf417SecurityLevel;

  /// PDF417 data columns 1–30. `null` lets the printer choose.
  final int? pdf417Columns;

  ZplBarcode({
    this.x = 0,
    this.y = 0,
    required this.data,
    this.type = ZplBarcodeType.code128,
    required this.height,
    this.orientation = ZplOrientation.normal,
    this.printInterpretationLine = true,
    this.printInterpretationLineAbove = false,
    this.moduleWidth,
    this.wideBarToNarrowBarRatio,
    this.alignment,
    this.maxWidth,
    this.magnification = 3,
    this.qrErrorCorrection = ZplQrErrorCorrection.medium,
    this.pdf417SecurityLevel = 0,
    this.pdf417Columns,
  }) : assert(magnification >= 1 && magnification <= 10),
       assert(pdf417SecurityLevel >= 0 && pdf417SecurityLevel <= 8),
       assert(
         pdf417Columns == null || (pdf417Columns >= 1 && pdf417Columns <= 30),
       );

  /// Approximate printed width in dots (see [estimateBarcodeWidth]).
  int get width => estimateBarcodeWidth(this);

  @override
  String toZpl(ZplConfiguration context) {
    final sb = StringBuffer();
    sb.writeln('^FO${getAlignedX(context)},$y');

    if (moduleWidth != null || wideBarToNarrowBarRatio != null) {
      final w = moduleWidth ?? '';
      final r = wideBarToNarrowBarRatio ?? '';
      sb.writeln('^BY$w,$r');
    }

    sb.write(emitBarcodeSymbology(this));
    return sb.toString();
  }

  @override
  int calculateWidth(ZplConfiguration config) => width;

  /// Calculate the X position based on alignment and available width.
  int getAlignedX(ZplConfiguration context) {
    if (alignment == null) return x;

    final labelWidth = maxWidth ?? context.printWidth ?? 406;
    return switch (alignment!) {
      ZplAlignment.center =>
        x + ((labelWidth - width) ~/ 2).clamp(0, labelWidth - 1),
      ZplAlignment.right => x + (labelWidth - width).clamp(0, labelWidth - 1),
      ZplAlignment.left => x,
    };
  }
}
