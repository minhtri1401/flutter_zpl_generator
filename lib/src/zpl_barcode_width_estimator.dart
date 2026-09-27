import 'enums.dart';
import 'preview/zpl_barcode_symbol_metrics.dart';
import 'zpl_barcode.dart';

/// Printed width of a [ZplBarcode] in dots, used by layout containers for
/// alignment.
///
/// Primary path: encode the data with `package:barcode` and multiply the real
/// module count by the module width, which matches what the printer (and
/// Labelary) produce. Quiet zones are not included because Zebra does not
/// print them. Falls back to a per-character estimate only when the data is
/// not encodable in the chosen symbology.
int estimateBarcodeWidth(ZplBarcode b) {
  final measured = measureBarcodeSymbol(b);
  if (measured != null) return measured.width.round();
  return _fallbackWidth(b);
}

int _fallbackWidth(ZplBarcode b) {
  final mw = b.moduleWidth ?? 2;
  final len = b.data.length;
  switch (b.type) {
    case ZplBarcodeType.code128:
    case ZplBarcodeType.gs1_128:
      return ((len * 11) + 35) * mw;
    case ZplBarcodeType.code39:
      return ((len * 13) + 26) * mw;
    case ZplBarcodeType.code93:
      return ((len * 9) + 38) * mw;
    case ZplBarcodeType.interleaved2of5:
      return ((len * 9) + 13) * mw;
    case ZplBarcodeType.ean13:
    case ZplBarcodeType.upcA:
      return 95 * mw;
    case ZplBarcodeType.ean8:
      return 67 * mw;
    case ZplBarcodeType.upcE:
      return 51 * mw;
    case ZplBarcodeType.qrCode:
      return 33 * b.magnification;
    case ZplBarcodeType.dataMatrix:
      return 16 * b.height;
    case ZplBarcodeType.pdf417:
      return ((17 * (b.pdf417Columns ?? 3)) + 69) * mw;
    case ZplBarcodeType.aztec:
      return 23 * b.magnification;
  }
}
