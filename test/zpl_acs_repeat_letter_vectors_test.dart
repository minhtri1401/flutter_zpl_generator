import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:image/image.dart' as img;

/// Repeat-letter values verified on Labelary (2026-09-27) by rendering
/// `^GFA,16,16,2,<body>` and measuring the inked width:
///   `GF,` → 4 px (one F nibble)   `HF,` → 8 px   `IF,` → 12 px
///   `gF,` → 20 nibbles (spills into the next row)   `YF,` → 19 nibbles
/// so G = 1, H = 2 … Y = 19 and g = 20 … z = 400.
void main() {
  late ZplImageInline encoder;

  setUp(() {
    final im = img.Image(width: 8, height: 1);
    encoder = ZplImageInline(image: img.encodePng(im));
  });

  test('a run of 2 uses H, a run of 3 uses I', () {
    expect(encoder.compressRow('FF00'), 'HF,');
    expect(encoder.compressRow('FFF0'), 'IF,');
    expect(encoder.compressRow('AA00'), 'HA,');
  });

  test('a run of 19 uses Y and a run of 20 uses g', () {
    expect(encoder.compressRow('${'F' * 19}0'), 'YF,');
    expect(encoder.compressRow('${'F' * 20}0'), 'gF,');
    expect(encoder.compressRow('${'F' * 21}0'), 'gFF,');
    expect(encoder.compressRow('${'F' * 22}0'), 'gFHF,'); // two runs, both valid
  });

  test('a single nibble is emitted without a repeat letter', () {
    expect(encoder.compressRow('F000'), 'F,');
    expect(encoder.compressRow('A5A5'), 'A5A5');
  });

  test('all-zero and all-one rows collapse to , and !', () {
    expect(encoder.compressRow('0000'), ',');
    expect(encoder.compressRow('FFFF'), '!');
  });
}
