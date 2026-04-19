import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

Uint8List _halfBlackHalfWhite16x16() {
  final i = img.Image(width: 16, height: 16);
  for (int y = 0; y < 16; y++) {
    for (int x = 0; x < 16; x++) {
      i.setPixel(
        x,
        y,
        y < 8 ? img.ColorRgb8(0, 0, 0) : img.ColorRgb8(255, 255, 255),
      );
    }
  }
  return img.encodePng(i);
}

void main() {
  group('ZplImageInline', () {
    final bytes = _halfBlackHalfWhite16x16();

    test('emits ^FO + ^GFA with ACS-compressed body inside format block', () {
      final c = ZplImageInline(x: 5, y: 7, image: bytes);
      final zpl = c.toZpl(const ZplConfiguration());
      expect(zpl, contains('^FO5,7'));
      expect(zpl, contains('^GFA,32,32,2,'));
      expect(zpl, contains('!'));
      expect(zpl, contains(','));
      expect(zpl, contains(':'));
      expect(zpl.trim().endsWith('^FS'), isTrue);
      expect(zpl, isNot(contains('~DG')));
    });

    test('is NOT a ZplControlCommand', () {
      final c = ZplImageInline(image: bytes);
      expect(c, isA<ZplCommand>());
      expect(c, isNot(isA<ZplControlCommand>()));
    });

    test('width/height post-resize (Bug 2 fix)', () {
      final c = ZplImageInline(image: bytes, targetWidth: 8);
      expect(c.width, 8);
      expect(c.height, 8);
    });
  });
}
