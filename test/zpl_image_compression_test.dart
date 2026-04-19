import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  late Uint8List testImageBytes;

  setUp(() {
    // 16x16 image: top half black, bottom half white.
    final image = img.Image(width: 16, height: 16);
    for (int y = 0; y < 16; y++) {
      for (int x = 0; x < 16; x++) {
        final color = (y < 8)
            ? img.ColorRgb8(0, 0, 0)
            : img.ColorRgb8(255, 255, 255);
        image.setPixel(x, y, color);
      }
    }
    testImageBytes = img.encodePng(image);
  });

  group('ZplImageDownload compression', () {
    test('uncompressed ~DG body contains raw ASCII hex rows', () async {
      final zpl = ZplImageDownload(image: testImageBytes)
          .toZpl(const ZplConfiguration());
      expect(zpl, contains('~DGIMG,32,2,'));
      expect(zpl, isNot(contains('^GFA')));
    });

    test('compression: acs inside ~DG uses shortcut characters', () async {
      final zpl = ZplImageDownload(
        image: testImageBytes,
        compression: ZplImageCompression.acs,
      ).toZpl(const ZplConfiguration());
      expect(zpl, contains('~DGIMG,'));
      expect(zpl, contains('!'));
      expect(zpl, contains(','));
      expect(zpl, contains(':'));
    });
  });

  group('ZplImageInline (one-shot ^GFA)', () {
    test('emits ^GFA inside format block with ACS shortcuts', () {
      final zpl = ZplImageInline(image: testImageBytes)
          .toZpl(const ZplConfiguration());
      expect(zpl, isNot(contains('~DG')));
      expect(zpl, contains('^GFA,32,32,2,'));
      expect(zpl, contains('!'));
      expect(zpl, contains(','));
      expect(zpl, contains(':'));
    });
  });
}
