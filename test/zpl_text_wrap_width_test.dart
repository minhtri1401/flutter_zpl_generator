import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  const config = ZplConfiguration(printWidth: 812);

  test('wrap width with maxWidth is the slot width, not reduced by x', () {
    final zpl = ZplText(
      x: 300,
      y: 10,
      text: 'wrap me',
      maxLines: 2,
      maxWidth: 200,
      paddingRight: 4,
    ).toZpl(config);
    expect(zpl, contains('^FB196,2,0,L,0'));
    expect(zpl, isNot(contains('^FB-')));
  });

  test('wrap width without maxWidth is measured from x to label edge', () {
    final zpl = ZplText(x: 300, text: 'wrap me', maxLines: 2).toZpl(config);
    expect(zpl, contains('^FB512,2,0,L,0'));
  });

  test('alignment hint with maxWidth at non-zero x keeps slot width', () {
    final zpl = ZplText(
      x: 300,
      text: 'wrap me',
      maxLines: 2,
      maxWidth: 200,
      alignment: ZplAlignment.left,
    ).toZpl(config);
    expect(zpl, contains('^FO300,0'));
    expect(zpl, contains('^FB200,2,0,L,0'));
  });
}
