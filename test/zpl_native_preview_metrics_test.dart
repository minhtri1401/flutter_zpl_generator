import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/src/preview/zpl_barcode_painter.dart';
import 'package:flutter_zpl_generator/src/preview/zpl_barcode_symbol_metrics.dart';
import 'package:flutter_zpl_generator/src/preview/zpl_text_painter.dart';

/// Offline checks for the numbers the native preview derives from a
/// command. Expected values were measured on Labelary at 8 dpmm.
void main() {
  ZplBarcode bc(
    String data,
    ZplBarcodeType t, {
    int h = 100,
    int? mw,
    int mag = 3,
  }) => ZplBarcode(
    data: data,
    type: t,
    height: h,
    moduleWidth: mw,
    magnification: mag,
  );

  group('measureBarcodeSymbol', () {
    test('Code 128 uses Zebra subset switching (ABC-12345 → 123 modules)', () {
      final m = measureBarcodeSymbol(
        bc('ABC-12345', ZplBarcodeType.code128, mw: 2),
      )!;
      expect(m.modulesWide, 123);
      expect(m.width, 246);
      expect(m.height, 100);
    });

    test('Code 39 applies the 3:1 default ratio (CODE39 → 127 modules)', () {
      final m = measureBarcodeSymbol(
        bc('CODE39', ZplBarcodeType.code39, mw: 2),
      )!;
      expect(m.modulesWide, 127);
      expect(m.barUnits.where((u) => u == 3.0), isNotEmpty);
    });

    test('Code 39 honours an explicit ratio', () {
      final b = ZplBarcode(
        data: 'CODE39',
        type: ZplBarcodeType.code39,
        height: 50,
        moduleWidth: 2,
        wideBarToNarrowBarRatio: 2.0,
      );
      expect(measureBarcodeSymbol(b)!.modulesWide, 103);
    });

    test('EAN-13 is 95 modules', () {
      final m = measureBarcodeSymbol(
        bc('5901234123457', ZplBarcodeType.ean13, mw: 3),
      )!;
      expect(m.modulesWide, 95);
      expect(m.width, 285);
    });

    test('Data Matrix scales by the module height parameter', () {
      final m = measureBarcodeSymbol(
        bc('DM-SAMPLE-2024', ZplBarcodeType.dataMatrix, h: 6),
      )!;
      expect(m.modulesWide, 16);
      expect(m.modulesHigh, 16);
      expect(m.width, 96);
    });

    test('QR picks version and level like the printer', () {
      final url = measureBarcodeSymbol(
        bc(
          'https://pub.dev/packages/flutter_zpl_generator',
          ZplBarcodeType.qrCode,
          h: 0,
        ),
      )!;
      expect(url.modulesWide, 33); // version 4 at magnification 3 → 99 dots
      expect(url.width, 99);
      final alnum = measureBarcodeSymbol(
        bc('HELLO WORLD 12345', ZplBarcodeType.qrCode, h: 0, mag: 4),
      )!;
      expect(alnum.modulesWide, 21); // alphanumeric mode fits version 1
      expect(alnum.qrIsDark, isNotNull);
    });

    test('returns null for data the symbology cannot encode', () {
      expect(
        measureBarcodeSymbol(bc('1234567', ZplBarcodeType.interleaved2of5)),
        isNull,
      );
    });
  });

  group('width estimator uses the measured symbol', () {
    test('no quiet zone is added', () {
      expect(bc('ABC-12345', ZplBarcodeType.code128, mw: 2).width, 246);
      expect(bc('12345', ZplBarcodeType.code128, mw: 2).width, 158);
    });
  });

  group('interpretation line and offsets', () {
    test('line height is 7 dots per module plus 6', () {
      expect(
        interpretationLineHeight(bc('X', ZplBarcodeType.code128, mw: 1)),
        13,
      );
      expect(
        interpretationLineHeight(bc('X', ZplBarcodeType.code128, mw: 2)),
        20,
      );
      expect(
        interpretationLineHeight(bc('X', ZplBarcodeType.code128, mw: 4)),
        34,
      );
    });

    test('only QR starts 10 dots below the origin', () {
      expect(symbolTopOffset(bc('X', ZplBarcodeType.qrCode)), 10);
      expect(symbolTopOffset(bc('X', ZplBarcodeType.dataMatrix)), 0);
    });
  });

  group('text calibration', () {
    test('font size puts the cap height at 75 % of the ZPL height', () {
      expect(previewFontSize(40) * 0.686, closeTo(30, 0.01));
    });

    test('horizontal scale follows the width/height ratio', () {
      expect(previewHorizontalScale(40, 40), closeTo(0.91, 0.001));
      expect(previewHorizontalScale(20, 40), closeTo(0.455, 0.001));
    });
  });
}
