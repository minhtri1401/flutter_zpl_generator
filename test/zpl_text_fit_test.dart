import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

/// The tests run without the preview font, so every glyph is as wide as the
/// font size and only the relations between the numbers are asserted.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const config = ZplConfiguration(printWidth: 800, labelLength: 400);

  ZplTextFit fit(
    String data, {
    int? maxWidth,
    int maxLines = 1,
    ZplAlignment? alignment,
    int x = 20,
    int paddingRight = 0,
  }) => measureZplText(
    ZplText(
      text: data,
      x: x,
      y: 10,
      fontHeight: 30,
      fontWidth: 30,
      maxWidth: maxWidth,
      maxLines: maxLines,
      alignment: alignment,
      paddingRight: paddingRight,
    ),
    config,
  );

  group('measureZplText', () {
    test('text with no block has no wrap width and never overflows', () {
      final f = fit('A long sentence that runs on and on');
      expect(f.wrapWidth, isNull);
      expect(f.lineCount, 1);
      expect(f.longestLine, greaterThan(200));
      expect(f.overflows, isFalse);
    });

    test('a one-line block narrower than the text overflows', () {
      final f = fit('AAAA BBBB CCCC', maxWidth: 200);
      expect(f.wrapWidth, 200);
      expect(f.lineCount, greaterThan(1));
      expect(f.maxLines, 1);
      expect(f.overflows, isTrue);
    });

    test('a one-line block wider than the text fits', () {
      final f = fit('AA', maxWidth: 200);
      expect(f.lineCount, 1);
      expect(f.longestLine, lessThan(200));
      expect(f.overflows, isFalse);
    });

    test('lines are counted past the limit, not clipped to it', () {
      final text = List.filled(12, 'WORD').join(' ');
      final tight = fit(text, maxWidth: 200, maxLines: 2);
      expect(tight.lineCount, greaterThan(2));
      expect(tight.overflows, isTrue);
      final roomy = fit(text, maxWidth: 200, maxLines: 20);
      expect(roomy.lineCount, tight.lineCount);
      expect(roomy.overflows, isFalse);
    });

    test('a word wider than the block overflows', () {
      expect(fit('AAAAAAAAAAAAAAAA', maxWidth: 100).overflows, isTrue);
    });

    test('an aligned block wraps at its width less the padding', () {
      final f = fit(
        'AA',
        maxWidth: 400,
        alignment: ZplAlignment.center,
        paddingRight: 100,
      );
      expect(f.wrapWidth, 300);
      expect(f.overflows, isFalse);
    });

    test('aligned text at x 0 wraps at the label width', () {
      final f = fit('AA', x: 0, alignment: ZplAlignment.right);
      expect(f.wrapWidth, 800);
    });

    test('a wrapping block without maxWidth runs to the label edge', () {
      final f = fit('AA', maxLines: 3, x: 200);
      expect(f.wrapWidth, 600);
      expect(f.overflows, isFalse);
    });

    test('empty text is one empty line', () {
      final f = fit('', maxWidth: 100);
      expect(f.lineCount, 1);
      expect(f.longestLine, 0);
      expect(f.overflows, isFalse);
    });
  });
}
