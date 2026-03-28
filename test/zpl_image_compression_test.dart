import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('ZplImage Compression Tests', () {
    late Uint8List testImageBytes;

    setUp(() {
      // Create a simple 16x16 image where
      // top half (8x16) is black and
      // bottom half (8x16) is white.
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

    test('generates uncompressed ZPL (~DG / ^XG) by default', () async {
      final zpl = ZplImage(image: testImageBytes);
      final generated = zpl.toZpl(const ZplConfiguration());

      expect(generated, contains('~DGIMG'));
      expect(generated, contains('^XGIMG,1,1^FS'));
      expect(generated, isNot(contains('^GFA')));
    });

    test('generates compressed ACS ZPL (^GFA) when instructed', () async {
      final zpl = ZplImage(
        image: testImageBytes,
        compression: ZplImageCompression.acs,
      );
      final generated = zpl.toZpl(const ZplConfiguration());

      // Should not contain ~DG
      expect(generated, isNot(contains('~DGIMG')));

      // Should contain ^GFA
      // Dimensions: 16 width -> 2 bytes width. 16 height. Total bytes = 32.
      expect(generated, contains('^GFA,32,32,2,'));

      // Since top half is black, bytes will be 'FF FF', which means all 'F's
      // The bottom half is white, bytes will be '00 00', which means all '0's
      expect(generated, contains('!')); // Shorthand for full line Fs
      expect(generated, contains(',')); // Shorthand for full line 0s
      expect(
        generated,
        contains(':'),
      ); // Shorthand for repeating exactly previous line
    });
  });
}
