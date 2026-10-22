import 'package:barcode/barcode.dart';

import '../enums.dart';
import '../gs1/gs1_element_string.dart';
import '../zpl_barcode.dart';
import '../zpl_barcode_enums.dart';

/// Maps a [ZplBarcode] to the `package:barcode` encoder used by the offline
/// preview and by the width estimator. QR carries its error-correction level
/// because it changes the symbol version (module count).
Barcode previewBarcodeFor(ZplBarcode b) => switch (b.type) {
  ZplBarcodeType.code128 => Barcode.code128(),
  ZplBarcodeType.gs1_128 => Barcode.gs128(),
  ZplBarcodeType.code39 => Barcode.code39(),
  ZplBarcodeType.code93 => Barcode.code93(),
  ZplBarcodeType.interleaved2of5 => Barcode.itf(),
  ZplBarcodeType.ean13 => Barcode.ean13(),
  ZplBarcodeType.ean8 => Barcode.ean8(),
  ZplBarcodeType.upcA => Barcode.upcA(),
  ZplBarcodeType.upcE => Barcode.upcE(),
  ZplBarcodeType.qrCode => Barcode.qrCode(
    errorCorrectLevel: _qrLevel(b.qrErrorCorrection),
  ),
  ZplBarcodeType.dataMatrix => Barcode.dataMatrix(),
  ZplBarcodeType.pdf417 => Barcode.pdf417(),
  ZplBarcodeType.aztec => Barcode.aztec(),
};

BarcodeQRCorrectionLevel _qrLevel(ZplQrErrorCorrection l) => switch (l) {
  ZplQrErrorCorrection.low => BarcodeQRCorrectionLevel.low,
  ZplQrErrorCorrection.medium => BarcodeQRCorrectionLevel.medium,
  ZplQrErrorCorrection.quartile => BarcodeQRCorrectionLevel.quartile,
  ZplQrErrorCorrection.high => BarcodeQRCorrectionLevel.high,
};

/// Whether the symbology is a 2D matrix/stacked code.
bool isTwoDimensional(ZplBarcodeType type) => switch (type) {
  ZplBarcodeType.qrCode ||
  ZplBarcodeType.dataMatrix ||
  ZplBarcodeType.pdf417 ||
  ZplBarcodeType.aztec => true,
  _ => false,
};

/// Draws [b] with the preview encoder. A GS1 Data Matrix is encoded with FNC1
/// first and a GS (codeword 30) after each variable-length value that another
/// AI follows, as the printer does; other symbols (and GS1 data that is not an
/// element string) use [previewBarcodeFor] on `b.data`.
Iterable<BarcodeElement> makePreviewElements(
  ZplBarcode b, {
  required double width,
  required double height,
}) {
  final elements = b.gs1 && b.type == ZplBarcodeType.dataMatrix
      ? Gs1ElementString.tryParse(b.data)
      : null;
  if (elements == null) {
    return previewBarcodeFor(b).make(b.data, width: width, height: height);
  }
  final encoder = DataMatrixEncoder()..fnc1();
  for (var i = 0; i < elements.length; i++) {
    final e = elements[i];
    encoder.ascii('${e.ai.code}${e.value}');
    if (e.ai.variableLength && i < elements.length - 1) encoder.ascii('\x1d');
  }
  return Barcode.dataMatrix().makeBytes(
    encoder.toBytes(),
    width: width,
    height: height,
  );
}
