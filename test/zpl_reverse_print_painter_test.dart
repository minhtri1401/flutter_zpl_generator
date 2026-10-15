import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:image/image.dart' as img;

bool _isInk(img.Pixel p) => (0.299 * p.r + 0.587 * p.g + 0.114 * p.b) < 128;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<img.Image> render(List<ZplCommand> commands) async {
    final raster = await const ZplRasterizer().render(
      ZplGenerator(
        config: const ZplConfiguration(printWidth: 400, labelLength: 100),
        commands: commands,
      ),
    );
    return img.decodePng(raster.png)!;
  }

  ZplBox bar() =>
      ZplBox(x: 0, y: 0, width: 400, height: 100, borderThickness: 100);

  group('reverse-print text over a box', () {
    test('keeps the full box and knocks the text out white', () async {
      final image = await render([
        bar(),
        ZplText(
          x: 50,
          y: 30,
          text: 'REVERSE',
          fontHeight: 40,
          fontWidth: 40,
          reversePrint: true,
        ),
      ]);

      for (final y in [2, 50, 97]) {
        expect(_isInk(image.getPixel(5, y)), isTrue, reason: 'x=5 y=$y');
        expect(_isInk(image.getPixel(395, y)), isTrue, reason: 'x=395 y=$y');
      }
      var white = 0;
      for (var y = 25; y < 75; y++) {
        for (var x = 50; x < 250; x++) {
          if (!_isInk(image.getPixel(x, y))) white++;
        }
      }
      expect(white, greaterThan(100));
    });

    test('keeps the full box behind aligned reverse-print text', () async {
      final image = await render([
        bar(),
        ZplText(
          x: 0,
          y: 30,
          text: 'CENTER',
          fontHeight: 40,
          fontWidth: 40,
          alignment: ZplAlignment.center,
          reversePrint: true,
        ),
      ]);

      expect(_isInk(image.getPixel(5, 50)), isTrue);
      expect(_isInk(image.getPixel(395, 50)), isTrue);
    });

    test(
      'a thick bar fills whenever the border covers the short side',
      () async {
        for (final t in [50, 100]) {
          final image = await render([
            ZplBox(x: 0, y: 0, width: 400, height: 100, borderThickness: t),
          ]);
          expect(_isInk(image.getPixel(5, 50)), isTrue, reason: 't=$t left');
          expect(_isInk(image.getPixel(395, 50)), isTrue, reason: 't=$t right');
          expect(_isInk(image.getPixel(200, 2)), isTrue, reason: 't=$t top');
        }
      },
    );

    test('a thin border stays hollow', () async {
      final image = await render([
        ZplBox(x: 0, y: 0, width: 400, height: 100, borderThickness: 4),
      ]);
      expect(_isInk(image.getPixel(2, 50)), isTrue);
      expect(_isInk(image.getPixel(200, 50)), isFalse);
    });

    test('prints black over white paper without a box', () async {
      final image = await render([
        ZplText(
          x: 50,
          y: 30,
          text: 'REVERSE',
          fontHeight: 40,
          fontWidth: 40,
          reversePrint: true,
        ),
      ]);

      // ^FR on an empty (white) background prints black, like the printer.
      var ink = 0;
      for (final p in image) {
        if (_isInk(p)) ink++;
      }
      expect(ink, greaterThan(100));
      expect(_isInk(image.getPixel(5, 50)), isFalse);
    });
  });

  group('thick ellipses', () {
    test('a wide ellipse whose border covers its height fills', () async {
      final raster = await const ZplRasterizer().render(
        ZplGenerator(
          config: const ZplConfiguration(printWidth: 400, labelLength: 100),
          commands: [
            ZplGraphicEllipse(
              x: 0,
              y: 0,
              width: 400,
              height: 100,
              borderThickness: 60,
            ),
          ],
        ),
      );
      // A filled 400 x 100 ellipse covers pi/4 of its bounding box.
      expect(raster.inkRatio, closeTo(3.14159265 / 4, 0.01));

      final image = await render([
        ZplGraphicEllipse(
          x: 0,
          y: 0,
          width: 400,
          height: 100,
          borderThickness: 60,
        ),
      ]);

      expect(_isInk(image.getPixel(200, 50)), isTrue);
      expect(_isInk(image.getPixel(200, 95)), isTrue);
      expect(_isInk(image.getPixel(120, 50)), isTrue);
      expect(_isInk(image.getPixel(10, 50)), isTrue);
      expect(_isInk(image.getPixel(390, 50)), isTrue);
      expect(_isInk(image.getPixel(5, 5)), isFalse);
    });

    test('a thin ellipse border stays hollow', () async {
      final image = await render([
        ZplGraphicEllipse(
          x: 0,
          y: 0,
          width: 400,
          height: 100,
          borderThickness: 4,
        ),
      ]);

      expect(_isInk(image.getPixel(200, 50)), isFalse);
      expect(_isInk(image.getPixel(200, 1)), isTrue);
    });
  });
}
