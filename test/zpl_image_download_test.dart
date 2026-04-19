import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

Uint8List _makePng(int w, int h) {
  final i = img.Image(width: w, height: h);
  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      i.setPixel(
        x,
        y,
        (y < h ~/ 2) ? img.ColorRgb8(0, 0, 0) : img.ColorRgb8(255, 255, 255),
      );
    }
  }
  return img.encodePng(i);
}

void main() {
  group('ZplImageDownload', () {
    final bytes = _makePng(16, 16);

    test('is a ZplControlCommand', () {
      final d = ZplImageDownload(image: bytes);
      expect(d, isA<ZplControlCommand>());
    });

    test('emits ~DG with graphic name, total bytes, width bytes, hex rows', () {
      final d = ZplImageDownload(image: bytes, graphicName: 'LOGO');
      final zpl = d.toZpl(const ZplConfiguration());
      expect(zpl, startsWith('~DGLOGO,32,2,'));
      expect(zpl, isNot(contains('^FO')));
      expect(zpl, isNot(contains('^XG')));
      expect(zpl, isNot(contains('^XA')));
    });

    test('defaults graphicName to IMG', () {
      final d = ZplImageDownload(image: bytes);
      expect(d.toZpl(const ZplConfiguration()), startsWith('~DGIMG,'));
    });

    test('compression: acs produces ACS-encoded body inside ~DG', () {
      final d = ZplImageDownload(
        image: bytes,
        compression: ZplImageCompression.acs,
      );
      final zpl = d.toZpl(const ZplConfiguration());
      expect(zpl, startsWith('~DGIMG,'));
      expect(zpl, contains('!'));
      expect(zpl, contains(','));
    });

    test('calculateWidth returns 0 (control command)', () {
      final d = ZplImageDownload(image: bytes);
      expect(d.calculateWidth(const ZplConfiguration()), 0);
    });

    test('width/height expose post-resize dimensions', () {
      final src = _makePng(100, 50);
      final d = ZplImageDownload(image: src, targetWidth: 50);
      expect(d.width, 50);
      expect(d.height, 25);
    });

    test('monochromePixels returns a grid of booleans', () {
      final d = ZplImageDownload(image: bytes);
      final px = d.getMonochromePixels();
      expect(px, isNotNull);
      expect(px!.width, 16);
      expect(px.height, 16);
      expect(px.pixels.length, 256);
    });
  });
}
