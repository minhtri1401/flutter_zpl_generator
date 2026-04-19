import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('ZplImageRecall', () {
    test('emits ^FO + ^XG with default magnification', () {
      const r = ZplImageRecall(x: 10, y: 20, graphicName: 'LOGO');
      final zpl = r.toZpl(const ZplConfiguration());
      expect(zpl, contains('^FO10,20'));
      expect(zpl, contains('^XGLOGO,1,1^FS'));
    });

    test('emits custom magnification factors', () {
      const r = ZplImageRecall(
        graphicName: 'BIG',
        magnificationX: 2,
        magnificationY: 3,
      );
      final zpl = r.toZpl(const ZplConfiguration());
      expect(zpl, contains('^XGBIG,2,3^FS'));
    });

    test('calculateWidth returns 0 when width field is null', () {
      const r = ZplImageRecall(graphicName: 'X');
      expect(r.calculateWidth(const ZplConfiguration()), 0);
    });

    test('calculateWidth returns the explicit width when provided', () {
      const r = ZplImageRecall(graphicName: 'X', width: 576);
      expect(r.calculateWidth(const ZplConfiguration()), 576);
    });

    test('is NOT a ZplControlCommand (it belongs inside the format block)', () {
      const r = ZplImageRecall(graphicName: 'X');
      expect(r, isA<ZplCommand>());
      expect(r, isNot(isA<ZplControlCommand>()));
    });
  });
}
