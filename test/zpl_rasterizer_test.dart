import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:image/image.dart' as img;

img.Image _decode(ZplRaster r) => img.decodePng(r.png)!;

bool _isInk(img.Pixel p) => (0.299 * p.r + 0.587 * p.g + 0.114 * p.b) < 128;

/// A 16 x 16 pure black and white diagonal-stripe PNG, so the inline image
/// needs no dithering and no resize.
Uint8List _stripes16() {
  final i = img.Image(width: 16, height: 16);
  for (int y = 0; y < 16; y++) {
    for (int x = 0; x < 16; x++) {
      final black = ((x + y) ~/ 2).isEven;
      i.setPixel(
        x,
        y,
        black ? img.ColorRgb8(0, 0, 0) : img.ColorRgb8(255, 255, 255),
      );
    }
  }
  return img.encodePng(i);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const rasterizer = ZplRasterizer();

  group('ZplRasterizer', () {
    test('an empty size throws and leaves the rasterizer usable', () async {
      final generator = ZplGenerator(
        config: const ZplConfiguration(printWidth: 20, labelLength: 20),
        commands: const [],
      );

      for (final size in [0, -5]) {
        await expectLater(
          rasterizer.render(generator, widthDots: size, heightDots: size),
          throwsException,
        );
      }
      final ok = await rasterizer.render(generator);
      expect((ok.width, ok.height), (20, 20));
    });

    test('uses explicit dimensions, one pixel per dot', () async {
      final raster = await rasterizer.render(
        ZplGenerator(
          config: const ZplConfiguration(printWidth: 300, labelLength: 400),
          commands: const [],
        ),
        widthDots: 120,
        heightDots: 80,
      );

      expect(raster.width, 120);
      expect(raster.height, 80);
      final decoded = _decode(raster);
      expect(decoded.width, 120);
      expect(decoded.height, 80);
    });

    test('defaults to the config size, else 406 x 609', () async {
      final configured = await rasterizer.render(
        ZplGenerator(
          config: const ZplConfiguration(printWidth: 300, labelLength: 200),
          commands: const [],
        ),
      );
      expect(configured.width, 300);
      expect(configured.height, 200);

      final bare = await rasterizer.render(
        ZplGenerator(config: const ZplConfiguration(), commands: const []),
      );
      expect(bare.width, 406);
      expect(bare.height, 609);
    });

    test('an empty generator gives ink 0 and an all-white png', () async {
      final raster = await rasterizer.render(
        ZplGenerator(
          config: const ZplConfiguration(printWidth: 64, labelLength: 48),
          commands: const [],
        ),
      );

      expect(raster.inkRatio, 0);
      final decoded = _decode(raster);
      for (final p in decoded) {
        expect([p.r, p.g, p.b, p.a], [255, 255, 255, 255]);
      }
    });

    test('a 100 x 50 filled box gives the exact ink ratio', () async {
      final raster = await rasterizer.render(
        ZplGenerator(
          config: const ZplConfiguration(printWidth: 406, labelLength: 609),
          commands: [
            ZplBox(x: 20, y: 30, width: 100, height: 50, borderThickness: 50),
          ],
        ),
      );

      expect(raster.inkRatio, 5000 / (406 * 609));
      final decoded = _decode(raster);
      var ink = 0;
      for (final p in decoded) {
        if (_isInk(p)) ink++;
      }
      expect(ink, 5000);
      expect(_isInk(decoded.getPixel(20, 30)), isTrue);
      expect(_isInk(decoded.getPixel(119, 79)), isTrue);
      expect(_isInk(decoded.getPixel(120, 80)), isFalse);
    });

    test('a box thinner than its border is widened to the border', () async {
      // ^GB10,100,30 and ^GB100,10,30: the printer (and Labelary) take the
      // border as the least width and height of the box.
      for (final (w, h, expectedW, expectedH) in [
        (10, 100, 30, 100),
        (100, 10, 100, 30),
        (10, 10, 30, 30),
      ]) {
        final raster = await rasterizer.render(
          ZplGenerator(
            config: const ZplConfiguration(printWidth: 200, labelLength: 200),
            commands: [
              ZplBox(x: 20, y: 40, width: w, height: h, borderThickness: 30),
            ],
          ),
        );

        final decoded = _decode(raster);
        var ink = 0;
        for (final p in decoded) {
          if (_isInk(p)) ink++;
        }
        expect(ink, expectedW * expectedH, reason: '^GB$w,$h,30');
        expect(_isInk(decoded.getPixel(20, 40)), isTrue);
        expect(
          _isInk(decoded.getPixel(20 + expectedW - 1, 40 + expectedH - 1)),
          isTrue,
          reason: '^GB$w,$h,30 reaches its widened corner',
        );
        expect(_isInk(decoded.getPixel(20 + expectedW, 40)), isFalse);
        expect(_isInk(decoded.getPixel(20, 40 + expectedH)), isFalse);
      }
    });

    test('a box wider than its border keeps its size', () async {
      final raster = await rasterizer.render(
        ZplGenerator(
          config: const ZplConfiguration(printWidth: 200, labelLength: 200),
          commands: [
            ZplBox(x: 20, y: 40, width: 60, height: 40, borderThickness: 20),
          ],
        ),
      );

      // 60 x 40 outline with a 20-dot border: the border covers half of the
      // short side, so the box is solid.
      expect(raster.inkRatio, 2400 / (200 * 200));
    });

    test('an inline image comes back with the same pixels', () async {
      final image = ZplImageInline(x: 7, y: 5, image: _stripes16());
      final expected = image.getMonochromePixels()!;
      expect(expected.width, 16);
      expect(expected.height, 16);

      final raster = await rasterizer.render(
        ZplGenerator(
          config: const ZplConfiguration(printWidth: 40, labelLength: 30),
          commands: [image],
        ),
      );

      final decoded = _decode(raster);
      var ink = 0;
      for (var y = 0; y < 30; y++) {
        for (var x = 0; x < 40; x++) {
          final inside = x >= 7 && x < 23 && y >= 5 && y < 21;
          final want = inside && expected.pixels[(y - 5) * 16 + (x - 7)];
          expect(_isInk(decoded.getPixel(x, y)), want, reason: 'pixel $x,$y');
          if (want) ink++;
        }
      }
      expect(ink, greaterThan(0));
      expect(raster.inkRatio, ink / (40 * 30));
    });

    test('two renders of the same label give equal bytes', () async {
      final generator = ZplGenerator(
        config: const ZplConfiguration(printWidth: 406, labelLength: 300),
        commands: [
          ZplText(text: 'Hello 123', x: 10, y: 10, fontHeight: 30),
          ZplBox(x: 10, y: 60, width: 200, height: 60, borderThickness: 3),
          ZplBarcode(
            data: '123456789',
            x: 10,
            y: 140,
            type: ZplBarcodeType.code128,
            height: 60,
          ),
        ],
      );

      final a = await rasterizer.render(generator);
      final b = await rasterizer.render(generator);

      expect(a.png, b.png);
      expect(a.inkRatio, b.inkRatio);
      expect(a.inkRatio, greaterThan(0));
    });

    test('renders a 300 dpi label', () async {
      final raster = await rasterizer.render(
        ZplGenerator(
          config: const ZplConfiguration(
            printWidth: 1200,
            labelLength: 1800,
            printDensity: ZplPrintDensity.d12,
          ),
          commands: [
            ZplBox(
              x: 100,
              y: 100,
              width: 400,
              height: 300,
              borderThickness: 300,
            ),
          ],
        ),
      );

      expect(raster.width, 1200);
      expect(raster.height, 1800);
      expect(raster.inkRatio, 120000 / (1200 * 1800));
      expect(_decode(raster).width, 1200);
    });

    test('default scale is unchanged', () async {
      final raster = await rasterizer.render(
        ZplGenerator(
          config: const ZplConfiguration(printWidth: 64, labelLength: 48),
          commands: const [],
        ),
      );

      expect(raster.scale, 1);
      expect((raster.width, raster.height), (64, 48));
      expect(_decode(raster).width, 64);
    });

    test('render at scale 3 is three times the size', () async {
      final raster = await rasterizer.render(
        ZplGenerator(
          config: const ZplConfiguration(printWidth: 100, labelLength: 50),
          commands: [
            ZplBox(x: 0, y: 0, width: 100, height: 50, borderThickness: 50),
          ],
        ),
        scale: 3,
      );

      expect(raster.width, 300);
      expect(raster.height, 150);
      expect(raster.scale, 3);
      final decoded = _decode(raster);
      expect(decoded.width, 300);
      expect(decoded.height, 150);
    });

    test('scaled raster keeps the same ink share', () async {
      final generator = ZplGenerator(
        config: const ZplConfiguration(printWidth: 100, labelLength: 50),
        commands: [
          ZplBox(x: 10, y: 10, width: 60, height: 30, borderThickness: 5),
        ],
      );

      final at1 = await rasterizer.render(generator);
      final at3 = await rasterizer.render(generator, scale: 3);

      expect(at3.inkRatio, closeTo(at1.inkRatio, 0.02));
    });

    test('fractional scale rounds the pixel size', () async {
      final raster = await rasterizer.render(
        ZplGenerator(
          config: const ZplConfiguration(printWidth: 406, labelLength: 609),
          commands: const [],
        ),
        scale: 1.97,
      );

      expect(raster.width, 800);
      expect(raster.height, 1200);
    });
  });
}
