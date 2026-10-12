import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  const config = ZplConfiguration(printWidth: 812);

  group('backslash inside a ^FB block', () {
    test('doubles every backslash before turning line breaks into \\&', () {
      expect(
        ZplText.fieldData(
          r'C:\temp'
          '\n'
          r'a\&b',
          inFieldBlock: true,
        ),
        r'C:\\temp\&a\\&b',
      );
    });

    test('leaves a backslash single outside a block', () {
      expect(ZplText.fieldData(r'a\b', inFieldBlock: false), r'a\b');
    });

    test('a multi-line text prints one backslash per backslash', () {
      final zpl = ZplText(
        x: 40,
        y: 10,
        text: 'C:\\temp\nnext',
        maxLines: 2,
        maxWidth: 400,
      ).toZpl(config);
      expect(zpl, contains(r'^FDC:\\temp\&next^FS'));
    });
  });

  group('^FH for ^ and ~', () {
    test('needsHex is true only for ^ and ~', () {
      expect(ZplFieldDataEscaper.needsHex('a_b c'), isFalse);
      expect(ZplFieldDataEscaper.needsHex('a~b'), isTrue);
      expect(ZplFieldDataEscaper.needsHex('a^b'), isTrue);
    });

    test('hexEscape writes _, ^ and ~ as hex and keeps everything else', () {
      expect(ZplFieldDataEscaper.hexEscape('a_b^c~dé'), 'a_5Fb_5Ec_7Edé');
    });

    test('text with a tilde gets ^FH and no bare tilde', () {
      final zpl = ZplText(
        x: 10,
        y: 10,
        text: '50% off ~ today_1',
      ).toZpl(config);
      expect(zpl, contains('^FH\n^FD50% off _7E today_5F1^FS'));
      expect(zpl, isNot(contains('~')));
    });

    test('text with a caret gets ^FH', () {
      final zpl = ZplText(x: 10, y: 10, text: 'A^B').toZpl(config);
      expect(zpl, contains('^FH\n^FDA_5EB^FS'));
    });

    test('text without ^ or ~ is unchanged and has no ^FH', () {
      final zpl = ZplText(x: 10, y: 10, text: r'a_b \ c').toZpl(config);
      expect(zpl, contains(r'^FDa_b \ c^FS'));
      expect(zpl, isNot(contains('^FH')));
    });

    test('a block with a tilde escapes after the block escapes', () {
      final zpl = ZplText(
        x: 10,
        y: 10,
        text: 'x~\ny',
        maxLines: 2,
        maxWidth: 400,
      ).toZpl(config);
      expect(
        zpl,
        contains(
          '^FH\n^FDx_7E'
          r'\&'
          'y^FS',
        ),
      );
    });

    test('serialized text with a tilde gets ^FH before ^SN', () {
      final zpl = ZplText(
        x: 10,
        y: 10,
        text: 'x~',
        serialization: const ZplSerialConfig(increment: 1),
      ).toZpl(config);
      expect(zpl, contains('^FH\n^SNx_7E,1,'));
    });
  });

  group('{{placeholders}} stay unescaped', () {
    test('hexEscape keeps {{name}} and escapes the rest', () {
      expect(
        ZplFieldDataEscaper.hexEscape('{{lot_no}}_x~'),
        '{{lot_no}}_5Fx_7E',
      );
    });

    test('hexEscape leaves text made only of placeholders unchanged', () {
      expect(ZplFieldDataEscaper.hexEscape('{{a_1b}} {{c}}'), '{{a_1b}} {{c}}');
    });

    test('hexEscape edge cases around braces and surrogate pairs', () {
      expect(ZplFieldDataEscaper.hexEscape('{{a_b'), '{{a_5Fb');
      // The inner {{a_b}} is the placeholder; the outer braces are plain text.
      expect(ZplFieldDataEscaper.hexEscape('{{{a_b}}}'), '{{{a_b}}}');
      expect(ZplFieldDataEscaper.hexEscape('😀~'), '😀_7E');
    });

    test('needsHex is false for a placeholder alone and true beside a ~', () {
      expect(ZplFieldDataEscaper.needsHex('{{a}}'), isFalse);
      expect(ZplFieldDataEscaper.needsHex('~{{a}}'), isTrue);
    });

    test('a ZplText with ~ keeps its placeholder', () {
      final zpl = ZplText(x: 10, y: 10, text: '~ {{lot_no}}').toZpl(config);
      expect(zpl, contains('^FH\n^FD_7E {{lot_no}}^FS'));
    });
  });
}
