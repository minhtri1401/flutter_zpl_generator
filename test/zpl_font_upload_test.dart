import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('ZplFontUpload', () {
    final bytes = Uint8List.fromList([0x00, 0x11, 0xAA, 0xFF]);

    test('is a ZplControlCommand', () {
      final f = ZplFontUpload(identifier: 'A', fontBytes: bytes);
      expect(f, isA<ZplControlCommand>());
      expect(f, isA<ZplCommand>());
    });

    test('emits ~DY with identifier, byte count, and uppercase hex body', () {
      final f = ZplFontUpload(identifier: 'A', fontBytes: bytes);
      final zpl = f.toZpl(const ZplConfiguration());
      expect(zpl, startsWith('~DYE:AFONT.TTF,B,T,4,,'));
      expect(zpl.trim().endsWith('0011AAFF'), isTrue);
    });

    test('rejects non-letter identifier', () {
      expect(
        () => ZplFontUpload(identifier: 'ab', fontBytes: bytes),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ZplFontUpload(identifier: '1', fontBytes: bytes),
        throwsA(isA<AssertionError>()),
      );
    });

    test('calculateWidth returns 0', () {
      final f = ZplFontUpload(identifier: 'A', fontBytes: bytes);
      expect(f.calculateWidth(const ZplConfiguration()), 0);
    });

    test('printerPath returns E:<id>FONT.TTF', () {
      final f = ZplFontUpload(identifier: 'B', fontBytes: bytes);
      expect(f.printerPath, 'E:BFONT.TTF');
    });
  });
}
