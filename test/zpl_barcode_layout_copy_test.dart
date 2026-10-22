import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  final gs1Dm = ZplBarcode(
    data: '(01)09501101530003(10)AB12',
    type: ZplBarcodeType.dataMatrix,
    height: 6,
    gs1: true,
  );
  final modeN = ZplBarcode(
    data: '>9ABC',
    type: ZplBarcodeType.code128,
    height: 50,
    code128Mode: ZplCode128Mode.none,
  );
  const config = ZplConfiguration();

  test('ZplColumn keeps gs1 and code128Mode on a barcode child', () {
    final direct = gs1Dm.toZpl(config);
    final inCol = ZplColumn(children: [gs1Dm]).toZpl(config);
    expect(inCol, contains('~1'));
    expect(direct, contains('~1'));
    expect(ZplColumn(children: [modeN]).toZpl(config), contains(',N,N'));
  });

  test('ZplGridRow keeps gs1 and code128Mode on a barcode child', () {
    ZplGridRow row(ZplBarcode b) =>
        ZplGridRow(children: [ZplGridCol(width: 12, child: b)]);
    expect(row(gs1Dm).toZpl(config), contains('~1'));
    expect(row(modeN).toZpl(config), contains(',N,N'));
  });

  test('ZplColumn and ZplGridRow keep QR and PDF417 settings', () {
    final qr = ZplBarcode(
      data: 'x',
      type: ZplBarcodeType.qrCode,
      height: 6,
      magnification: 7,
      qrErrorCorrection: ZplQrErrorCorrection.high,
    );
    final pdf = ZplBarcode(
      data: 'x',
      type: ZplBarcodeType.pdf417,
      height: 6,
      pdf417SecurityLevel: 4,
      pdf417Columns: 9,
    );
    for (final b in [qr, pdf]) {
      final want = b.toZpl(config).split('\n').where((l) => l.startsWith('^B'));
      final col = ZplColumn(children: [b]).toZpl(config);
      final row = ZplGridRow(
        children: [ZplGridCol(width: 12, child: b)],
      ).toZpl(config);
      for (final l in want) {
        if (l.startsWith('^BY')) continue;
        expect(col, contains(l));
        expect(row, contains(l));
      }
    }
  });
}
