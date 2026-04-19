import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

Uint8List _png(int w, int h) =>
    img.encodePng(img.Image(width: w, height: h));

void main() {
  group('Bug 2 regression — post-resize getters', () {
    test('ZplImageDownload height reflects aspect-scaled resize', () {
      final d = ZplImageDownload(image: _png(1080, 2400), targetWidth: 576);
      expect(d.width, 576);
      expect(d.height, 1280);
    });

    test('ZplImageDownload width reflects aspect-scaled resize from targetHeight',
        () {
      final d = ZplImageDownload(image: _png(1080, 2400), targetHeight: 1000);
      expect(d.width, 450);
      expect(d.height, 1000);
    });

    test('no resize → original dimensions', () {
      final d = ZplImageDownload(image: _png(200, 100));
      expect(d.width, 200);
      expect(d.height, 100);
    });

    test('ZplImageInline getters mirror ZplImageDownload behaviour', () {
      final c = ZplImageInline(image: _png(1080, 2400), targetWidth: 576);
      expect(c.width, 576);
      expect(c.height, 1280);
    });

    test('maintainAspect: false lets both axes differ independently', () {
      final d = ZplImageDownload(
        image: _png(1080, 2400),
        targetWidth: 576,
        targetHeight: 500,
        maintainAspect: false,
      );
      expect(d.width, 576);
      expect(d.height, 500);
    });
  });
}
