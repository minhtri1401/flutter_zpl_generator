import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  const cfg = ZplConfiguration(printWidth: 812);

  String zpl(ZplBarcode b) => b.toZpl(cfg);

  group('new 1D symbologies', () {
    test('GS1-128 uses ^BC mode D so the printer inserts FNC1', () {
      final out = zpl(
        ZplBarcode(
          data: '(01)09501101530003',
          type: ZplBarcodeType.gs1_128,
          height: 80,
        ),
      );
      expect(out, contains('^BCN,80,Y,N,N,D\n'));
      expect(out, contains('^FD(01)09501101530003^FS'));
    });

    test('Code 93 emits ^BA', () {
      final out = zpl(
        ZplBarcode(data: 'CODE93', type: ZplBarcodeType.code93, height: 60),
      );
      expect(out, contains('^BAN,60,Y,N,N\n^FDCODE93^FS'));
    });

    test('Interleaved 2 of 5 emits ^B2', () {
      final out = zpl(
        ZplBarcode(
          data: '12345678',
          type: ZplBarcodeType.interleaved2of5,
          height: 60,
          printInterpretationLine: false,
        ),
      );
      expect(out, contains('^B2N,60,N,N,N,N\n^FD12345678^FS'));
    });

    test('EAN-8 emits ^B8', () {
      final out = zpl(
        ZplBarcode(data: '9638507', type: ZplBarcodeType.ean8, height: 60),
      );
      expect(out, contains('^B8N,60,Y,N\n^FD9638507^FS'));
    });

    test('UPC-E emits ^B9', () {
      final out = zpl(
        ZplBarcode(data: '1234567', type: ZplBarcodeType.upcE, height: 60),
      );
      expect(out, contains('^B9N,60,Y,N,Y\n^FD1234567^FS'));
    });
  });

  group('new 2D symbologies', () {
    test('PDF417 emits ^B7 with security level and optional columns', () {
      final out = zpl(
        ZplBarcode(
          data: 'PDF417 DATA',
          type: ZplBarcodeType.pdf417,
          height: 8,
          pdf417SecurityLevel: 3,
          pdf417Columns: 4,
        ),
      );
      expect(out, contains('^B7N,8,3,4,,N\n^FDPDF417 DATA^FS'));
    });

    test('PDF417 leaves columns blank when unset', () {
      final out = zpl(
        ZplBarcode(data: 'x', type: ZplBarcodeType.pdf417, height: 8),
      );
      expect(out, contains('^B7N,8,0,,,N\n'));
    });

    test('Aztec emits ^BO with magnification', () {
      final out = zpl(
        ZplBarcode(
          data: 'AZTEC',
          type: ZplBarcodeType.aztec,
          height: 0,
          magnification: 5,
        ),
      );
      expect(out, contains('^BON,5,N,0,N,1\n^FDAZTEC^FS'));
    });
  });

  group('QR Code parameters', () {
    test('defaults: model 2, magnification 3, level M, and the ^FD prefix', () {
      final out = zpl(
        ZplBarcode(data: 'hello', type: ZplBarcodeType.qrCode, height: 0),
      );
      expect(out, contains('^BQN,2,3,M\n^FDMA,hello^FS'));
    });

    test('custom error correction and magnification', () {
      final out = zpl(
        ZplBarcode(
          data: 'https://example.com',
          type: ZplBarcodeType.qrCode,
          height: 0,
          magnification: 6,
          qrErrorCorrection: ZplQrErrorCorrection.high,
          orientation: ZplOrientation.rotated90,
        ),
      );
      expect(out, contains('^BQR,2,6,H\n^FDHA,https://example.com^FS'));
    });

    test('magnification scales the width estimate', () {
      final small = ZplBarcode(
        data: 'abc',
        type: ZplBarcodeType.qrCode,
        height: 0,
        magnification: 2,
      ).width;
      final big = ZplBarcode(
        data: 'abc',
        type: ZplBarcodeType.qrCode,
        height: 0,
        magnification: 4,
      ).width;
      expect(big, small * 2);
    });
  });

  group('existing symbologies are unchanged', () {
    test('Code 128 still uses automatic subset mode', () {
      final out = zpl(ZplBarcode(data: '1234', height: 100));
      expect(out, contains('^BCN,100,Y,N,N,A\n^FD1234^FS'));
    });

    test('Data Matrix still emits ^BX with ECC 200', () {
      final out = zpl(
        ZplBarcode(data: 'DM', type: ZplBarcodeType.dataMatrix, height: 6),
      );
      expect(out, contains('^BXN,6,200\n^FDDM^FS'));
    });
  });

  group('width estimates', () {
    test('every symbology returns a positive width', () {
      for (final t in ZplBarcodeType.values) {
        final w = ZplBarcode(data: '0123456789', type: t, height: 50).width;
        expect(w, greaterThan(0), reason: '$t');
      }
    });

    test('fixed-length retail codes ignore data length', () {
      int w(ZplBarcodeType t, String d) =>
          ZplBarcode(data: d, type: t, height: 50).width;
      expect(w(ZplBarcodeType.ean8, '1234567'), w(ZplBarcodeType.ean8, '1'));
      expect(w(ZplBarcodeType.upcE, '1234567'), w(ZplBarcodeType.upcE, '1'));
      expect(
        w(ZplBarcodeType.ean8, '1'),
        lessThan(w(ZplBarcodeType.ean13, '1')),
      );
    });

    test('right alignment keeps the barcode inside maxWidth', () {
      final b = ZplBarcode(
        data: '12345678',
        type: ZplBarcodeType.interleaved2of5,
        height: 50,
        alignment: ZplAlignment.right,
        maxWidth: 400,
      );
      expect(b.getAlignedX(cfg) + b.width, lessThanOrEqualTo(400));
    });
  });

  group('validation', () {
    test('rejects out-of-range magnification and PDF417 settings', () {
      expect(
        () => ZplBarcode(data: 'x', height: 1, magnification: 11),
        throwsAssertionError,
      );
      expect(
        () => ZplBarcode(data: 'x', height: 1, pdf417SecurityLevel: 9),
        throwsAssertionError,
      );
      expect(
        () => ZplBarcode(data: 'x', height: 1, pdf417Columns: 0),
        throwsAssertionError,
      );
    });
  });
}
