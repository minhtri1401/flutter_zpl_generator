import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  const config = ZplConfiguration(printWidth: 812);

  test('newlines become \\& inside a ^FB block', () {
    final t = ZplText(
      x: 40,
      y: 10,
      text: 'Jane Doe\n1 Example St\r\nSaigon',
      maxLines: 3,
      maxWidth: 700,
    );
    final zpl = t.toZpl(config);
    expect(zpl, contains('^FB'));
    expect(zpl, contains(r'^FDJane Doe\&1 Example St\&Saigon^FS'));
    expect(t.renderedText, 'Jane Doe\n1 Example St\nSaigon');
  });

  test('newlines are dropped when no block is emitted', () {
    final t = ZplText(x: 40, text: 'a\nb');
    expect(t.toZpl(config), contains('^FDab^FS'));
    expect(t.renderedText, 'ab');
    expect(t.emitsFieldBlock, isFalse);
  });

  test('centred block at x == 0 keeps line breaks', () {
    final t = ZplText(text: 'a\nb', alignment: ZplAlignment.center);
    expect(t.emitsFieldBlock, isTrue);
    expect(t.toZpl(config), contains(r'^FDa\&b^FS'));
  });

  test('serialized fields get the same treatment', () {
    final t = ZplText(
      text: 'x\ny',
      maxLines: 2,
      serialization: const ZplSerialConfig(increment: 1),
    );
    expect(t.toZpl(config), contains(r'^SNx\&y,1'));
  });
}
