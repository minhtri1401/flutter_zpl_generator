import 'package:barcode/barcode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/src/preview/zpl_barcode_preview_mapping.dart';

void main() {
  code128ModeNEmitTests();
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

    test('GS1-128 separates a variable-length AI from the next with >8', () {
      final out = zpl(
        ZplBarcode(
          data: '(10)ABC(21)123',
          type: ZplBarcodeType.gs1_128,
          height: 80,
        ),
      );
      expect(out, contains('^FD(10)ABC>8(21)123^FS'));
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

  group('GS1 Data Matrix', () {
    const text = '(01)09501101530003(10){{lot}}(21){{sn}}';

    test('emits the escape parameter, FNC1 and group separators', () {
      final out = zpl(
        ZplBarcode(
          data: text,
          type: ZplBarcodeType.dataMatrix,
          height: 6,
          gs1: true,
        ),
      );
      expect(
        out,
        contains(
          '^BXN,6,200,,,,@\n^FD@10109501101530003'
          '10{{lot}}@d02921{{sn}}^FS',
        ),
      );
    });

    test('a concrete element string uses @ and no ~ anywhere', () {
      final out = zpl(
        ZplBarcode(
          data: '(01)09501101530003(17)261231(10)A1(21)XYZ',
          type: ZplBarcodeType.dataMatrix,
          height: 6,
          gs1: true,
        ),
      );
      expect(
        out,
        contains(
          '^BXN,6,200,,,,@\n'
          '^FD@101095011015300031726123110A1@d02921XYZ^FS',
        ),
      );
      expect(out.contains('~'), isFalse);
    });

    test('a value holding @ falls back to plain', () {
      final out = zpl(
        ZplBarcode(
          data: '(10)A@1B',
          type: ZplBarcodeType.dataMatrix,
          height: 6,
          gs1: true,
        ),
      );
      expect(out, contains('^BXN,6,200\n'));
    });

    test('plain Data Matrix is emitted exactly as before', () {
      final out = zpl(
        ZplBarcode(data: text, type: ZplBarcodeType.dataMatrix, height: 6),
      );
      expect(out, contains('^BXN,6,200\n^FD$text^FS'));
    });

    test('gs1 on other symbologies is ignored', () {
      final a = zpl(ZplBarcode(data: '1234', height: 100));
      final b = zpl(ZplBarcode(data: '1234', height: 100, gs1: true));
      expect(b, a);
    });

    test('data that is not an element string falls back to plain', () {
      final out = zpl(
        ZplBarcode(
          data: 'not gs1',
          type: ZplBarcodeType.dataMatrix,
          height: 6,
          gs1: true,
        ),
      );
      expect(out, contains('^BXN,6,200\n^FDnot gs1^FS'));
      final inj = zpl(
        ZplBarcode(
          data: '(10)A@d029B',
          type: ZplBarcodeType.dataMatrix,
          height: 6,
          gs1: true,
        ),
      );
      expect(inj, contains('^BXN,6,200\n'));
    });

    test('the preview starts the symbol with FNC1 and uses GS', () {
      const concrete = '(01)09501101530003(10)A1(21)5';
      ZplBarcode make({required bool gs1, String data = concrete}) =>
          ZplBarcode(
            data: data,
            type: ZplBarcodeType.dataMatrix,
            height: 6,
            gs1: gs1,
          );
      List<(double, double, double)> key(Iterable<BarcodeElement> els) => els
          .whereType<BarcodeBar>()
          .map((e) => (e.left, e.top, e.width))
          .toList();
      List<(double, double, double)> bars(ZplBarcode b) =>
          key(makePreviewElements(b, width: 200, height: 200));

      final expected = key(
        Barcode.dataMatrix().makeBytes(
          (DataMatrixEncoder()
                ..fnc1()
                ..ascii('0109501101530003')
                ..ascii('10A1')
                ..ascii('\x1d')
                ..ascii('215'))
              .toBytes(),
          width: 200,
          height: 200,
        ),
      );
      expect(bars(make(gs1: true)), expected);
      expect(bars(make(gs1: true)), isNot(bars(make(gs1: false))));
      // Not an element string: drawn as plain data.
      expect(
        bars(make(gs1: true, data: 'zz')),
        bars(make(gs1: false, data: 'zz')),
      );
    });
  });
}

void code128ModeNEmitTests() {
  group('code128 mode N emit', () {
    String zpl(ZplBarcode b) => b.toZpl(ZplConfiguration());

    test('none emits ^BC…,N,N with the data', () {
      final out = zpl(
        ZplBarcode(
          data: '>9X001ABCDE1',
          height: 80,
          moduleWidth: 2,
          printInterpretationLine: false,
          code128Mode: ZplCode128Mode.none,
        ),
      );
      expect(out, contains('^BY2'));
      expect(out, contains('^BCN,80,N,N,N,N'));
      expect(out, contains('^FD>9X001ABCDE1^FS'));
    });

    test('automatic stays ^BC…,N,A', () {
      final out = zpl(ZplBarcode(data: 'ABC', height: 80));
      expect(out, contains('^BCN,80,Y,N,N,A'));
    });
  });
}
