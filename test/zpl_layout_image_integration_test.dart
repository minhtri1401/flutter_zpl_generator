import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

Uint8List _png(int w, int h) =>
    img.encodePng(img.Image(width: w, height: h));

void main() {
  group('layout containers x new image commands', () {
    test('ZplColumn places ZplImageRecall with explicit width/height', () {
      const recall = ZplImageRecall(
        graphicName: 'LOGO',
        width: 200,
        height: 80,
      );
      final col = ZplColumn(
        x: 10,
        y: 20,
        spacing: 5,
        children: [recall],
      );
      final zpl = col.toZpl(const ZplConfiguration(printWidth: 576));
      expect(zpl, contains('^FO10,20'));
      expect(zpl, contains('^XGLOGO,1,1^FS'));
    });

    test('ZplColumn stacks two ZplImageInline children with renderedHeight', () {
      final inline = ZplImageInline(
        image: _png(64, 32),
        targetWidth: 64,
      );
      final col = ZplColumn(
        x: 0,
        y: 0,
        spacing: 0,
        children: [inline, inline],
      );
      final zpl = col.toZpl(const ZplConfiguration(printWidth: 576));
      final firstFo = zpl.indexOf('^FO0,0');
      final secondFo = zpl.indexOf('^FO0,32');
      expect(firstFo, isNonNegative);
      expect(secondFo, greaterThan(firstFo));
    });

    test('ZplGridRow carries ZplImageRecall through repositioning', () {
      final row = ZplGridRow(
        x: 0,
        y: 0,
        children: [
          ZplGridCol(
            width: 6,
            child: const ZplImageRecall(
              graphicName: 'LEFT',
              width: 100,
              height: 50,
            ),
          ),
          ZplGridCol(
            width: 6,
            child: const ZplImageRecall(
              graphicName: 'RIGHT',
              width: 100,
              height: 50,
            ),
          ),
        ],
      );
      final zpl = row.toZpl(const ZplConfiguration(printWidth: 600));
      expect(zpl, contains('^XGLEFT,1,1^FS'));
      expect(zpl, contains('^XGRIGHT,1,1^FS'));
      final leftFo = RegExp(r'\^FO(\d+),\d+\n\^XGLEFT').firstMatch(zpl);
      final rightFo = RegExp(r'\^FO(\d+),\d+\n\^XGRIGHT').firstMatch(zpl);
      expect(leftFo, isNotNull);
      expect(rightFo, isNotNull);
      expect(
        int.parse(rightFo!.group(1)!),
        greaterThan(int.parse(leftFo!.group(1)!)),
      );
    });
  });
}
