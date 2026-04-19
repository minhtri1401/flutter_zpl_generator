import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

Uint8List _png(int w, int h) =>
    img.encodePng(img.Image(width: w, height: h));

void main() {
  group('ZplGenerator two-phase build (Bug 1)', () {
    test('~DG precedes ^XA when a ZplImageDownload is present', () async {
      final gen = ZplGenerator(
        commands: [
          ZplImageDownload(image: _png(16, 16), graphicName: 'LOGO'),
          const ZplImageRecall(graphicName: 'LOGO'),
        ],
      );
      final zpl = await gen.build();
      final dgIdx = zpl.indexOf('~DG');
      final xaIdx = zpl.indexOf('^XA');
      expect(dgIdx, isNonNegative);
      expect(xaIdx, isNonNegative);
      expect(dgIdx, lessThan(xaIdx));
    });

    test('~DY precedes ^XA when a ZplFontUpload is present', () async {
      final font = ZplFontUpload(
        identifier: 'A',
        fontBytes: Uint8List.fromList([0x01, 0x02]),
      );
      final gen = ZplGenerator(commands: [font]);
      final zpl = await gen.build();
      expect(zpl.indexOf('~DY'), lessThan(zpl.indexOf('^XA')));
    });

    test('multiple control commands preserve input order, all pre-^XA', () async {
      final fontA = ZplFontUpload(
        identifier: 'A',
        fontBytes: Uint8List.fromList([1]),
      );
      final dl = ZplImageDownload(image: _png(8, 8), graphicName: 'G1');
      final fontB = ZplFontUpload(
        identifier: 'B',
        fontBytes: Uint8List.fromList([2]),
      );
      final gen = ZplGenerator(commands: [fontA, dl, fontB]);
      final zpl = await gen.build();
      final idxA = zpl.indexOf('~DYE:AFONT.TTF');
      final idxDg = zpl.indexOf('~DGG1');
      final idxB = zpl.indexOf('~DYE:BFONT.TTF');
      final idxXa = zpl.indexOf('^XA');
      expect(idxA, lessThan(idxDg));
      expect(idxDg, lessThan(idxB));
      expect(idxB, lessThan(idxXa));
    });

    test('format-only commands still produce a valid ^XA…^XZ block', () async {
      final gen = ZplGenerator(
        commands: [ZplText(x: 0, y: 0, text: 'Hi')],
      );
      final zpl = await gen.build();
      expect(zpl, contains('^XA'));
      expect(zpl, contains('^FDHi^FS'));
      expect(zpl, contains('^XZ'));
      expect(zpl, isNot(contains('~D')));
    });

    test('control commands never appear inside ^XA…^XZ', () async {
      final gen = ZplGenerator(
        commands: [
          ZplImageDownload(image: _png(8, 8)),
          const ZplImageRecall(graphicName: 'IMG'),
        ],
      );
      final zpl = await gen.build();
      final xa = zpl.indexOf('^XA');
      final xz = zpl.indexOf('^XZ');
      final body = zpl.substring(xa, xz);
      expect(body, isNot(contains('~DG')));
      expect(body, isNot(contains('~DY')));
    });
  });
}
