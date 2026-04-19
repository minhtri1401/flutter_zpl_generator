import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

Uint8List _png(int w, int h) =>
    img.encodePng(img.Image(width: w, height: h));

void main() {
  group('ZplGenerator.autoLabelLengthFromFirstImage (Bug 3)', () {
    test('flag false → no ^LL emitted from image', () async {
      final gen = ZplGenerator(
        commands: [ZplImageDownload(image: _png(576, 320))],
      );
      final zpl = await gen.build();
      expect(zpl, isNot(contains('^LL')));
    });

    test('flag true + no image → no ^LL', () async {
      final gen = ZplGenerator(
        autoLabelLengthFromFirstImage: true,
        commands: [ZplText(x: 0, y: 0, text: 'hi')],
      );
      final zpl = await gen.build();
      expect(zpl, isNot(contains('^LL')));
    });

    test('flag true + image → ^LL equals image height', () async {
      final gen = ZplGenerator(
        autoLabelLengthFromFirstImage: true,
        commands: [ZplImageDownload(image: _png(576, 320))],
      );
      final zpl = await gen.build();
      expect(zpl, contains('^LL320'));
    });

    test('flag true + image + explicit labelLength → explicit wins', () async {
      final gen = ZplGenerator(
        config: const ZplConfiguration(labelLength: 500),
        autoLabelLengthFromFirstImage: true,
        commands: [ZplImageDownload(image: _png(576, 320))],
      );
      final zpl = await gen.build();
      expect(zpl, contains('^LL500'));
      expect(zpl, isNot(contains('^LL320')));
    });

    test('flag true + aspect-scaled image → ^LL equals post-resize height',
        () async {
      final gen = ZplGenerator(
        autoLabelLengthFromFirstImage: true,
        commands: [
          ZplImageDownload(image: _png(1080, 2400), targetWidth: 576),
        ],
      );
      final zpl = await gen.build();
      expect(zpl, contains('^LL1280'));
    });

    test('^LL is inside ^XA…^XZ, not in the control phase', () async {
      final gen = ZplGenerator(
        autoLabelLengthFromFirstImage: true,
        commands: [ZplImageDownload(image: _png(576, 320))],
      );
      final zpl = await gen.build();
      final xa = zpl.indexOf('^XA');
      final ll = zpl.indexOf('^LL');
      final xz = zpl.indexOf('^XZ');
      expect(xa, lessThan(ll));
      expect(ll, lessThan(xz));
    });
  });
}
