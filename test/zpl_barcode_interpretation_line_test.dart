import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/src/preview/zpl_barcode_painter.dart';
import 'package:flutter_zpl_generator/src/preview/zpl_barcode_symbol_metrics.dart';

/// The preview's human-readable line must read like the Zebra printout,
/// e.g. "5 901234 123457" for the EAN-13 above.
void main() {
  main2();
  ZplBarcode bc(String data, ZplBarcodeType t) => ZplBarcode(
    data: data,
    type: t,
    height: 100,
    moduleWidth: 3,
    magnification: 3,
  );

  test('ean13 interpretation line has 13 digits with the first left of the '
      'guard', () {
    final p = debugBarcodeTextPlacements(
      bc('5901234123457', ZplBarcodeType.ean13),
    );
    expect(p.map((e) => e.text).join(), '5901234123457');
    expect(p, hasLength(13));
    expect(p.first.text, '5');
    // Left of the start guard, in the quiet zone (about 30 dots at mw 3).
    expect(p.first.left, inInclusiveRange(-35, -15));
    expect(p.first.left + p.first.width, lessThanOrEqualTo(0));
    expect(p.skip(1).every((e) => e.left >= 0), isTrue);
  });

  test('ean13 bars still start at the field origin', () {
    final m = measureBarcodeSymbol(bc('5901234123457', ZplBarcodeType.ean13))!;
    expect(m.width, 285);
    final p = debugBarcodeTextPlacements(
      bc('5901234123457', ZplBarcodeType.ean13),
    );
    // Second digit sits under the first bar group, inside the symbol.
    expect(p[1].left, greaterThan(0));
    expect(p.last.left + p.last.width, lessThanOrEqualTo(m.width + 0.5));
  });

  test("upc-a and ean-8 interpretation lines match Zebra's layout", () {
    final upc = debugBarcodeTextPlacements(
      bc('012345678905', ZplBarcodeType.upcA),
    );
    expect(upc.map((e) => e.text).join(), '012345678905');
    expect(upc.first.left, lessThan(0)); // number-system digit outside left
    expect(upc.last.left, greaterThan(250)); // check digit outside right

    final ean8 = debugBarcodeTextPlacements(
      bc('96385074', ZplBarcodeType.ean8),
    );
    expect(ean8.map((e) => e.text).join(), '96385074');
    expect(ean8.every((e) => e.left >= 0), isTrue);
  });
}

void main2() {
  test('mode N hides the start invocation in the interpretation line', () {
    final b = ZplBarcode(
      data: '>9X001ABCDE1',
      height: 100,
      moduleWidth: 2,
      code128Mode: ZplCode128Mode.none,
    );
    final p = debugBarcodeTextPlacements(b);
    expect(p.map((e) => e.text).join(), 'X001ABCDE1');
    expect(measureBarcodeSymbol(b)!.width, 290);
  });

  test('mode N with unencodable data has no metrics', () {
    final b = ZplBarcode(
      data: '>9abc',
      height: 100,
      code128Mode: ZplCode128Mode.none,
    );
    expect(measureBarcodeSymbol(b), isNull);
  });
}
