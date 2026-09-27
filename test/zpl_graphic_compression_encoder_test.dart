import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/src/zpl_graphic_compression_encoder.dart';
import 'package:image/image.dart' as img;

/// Splits `:TAG:<b64>:<crc>` into its parts.
({String tag, String b64, String crc}) _parseBody(String body) {
  final m = RegExp(
    r':(B64|Z64):([A-Za-z0-9+/=]+):([0-9a-f]{4})',
  ).firstMatch(body);
  expect(m, isNotNull, reason: 'body should be :TAG:base64:crc — got $body');
  return (tag: m!.group(1)!, b64: m.group(2)!, crc: m.group(3)!);
}

void main() {
  // 16x16: top half black, bottom half white → 2 bytes/row, 32 bytes.
  late Uint8List png;
  final expectedBytes = Uint8List.fromList([
    ...List.filled(16, 0xFF),
    ...List.filled(16, 0x00),
  ]);

  setUp(() {
    final image = img.Image(width: 16, height: 16);
    for (int y = 0; y < 16; y++) {
      for (int x = 0; x < 16; x++) {
        image.setPixel(
          x,
          y,
          y < 8 ? img.ColorRgb8(0, 0, 0) : img.ColorRgb8(255, 255, 255),
        );
      }
    }
    png = img.encodePng(image);
  });

  group('crc16Xmodem', () {
    test('standard check vector 123456789 → 0x31C3', () {
      expect(crc16Xmodem(ascii.encode('123456789')), 0x31C3);
    });

    test('empty input → 0', () {
      expect(crc16Xmodem(const []), 0);
    });
  });

  group('packHexRows', () {
    test('packs two hex chars per byte, rows in order', () {
      expect(packHexRows(['FF00', '0F0F']), [0xFF, 0x00, 0x0F, 0x0F]);
    });

    test('empty rows → empty bytes', () {
      expect(packHexRows(const []), isEmpty);
    });
  });

  group('B64 body', () {
    test('round-trips to the packed bitmap with a valid CRC', () {
      final body = ZplImageDownload(
        image: png,
        ditheringAlgorithm: ZplDitheringAlgorithm.threshold,
        compression: ZplImageCompression.b64,
      ).graphicBody(ZplImageCompression.b64);
      final p = _parseBody(body);
      expect(p.tag, 'B64');
      expect(base64.decode(p.b64), expectedBytes);
      expect(
        p.crc,
        crc16Xmodem(ascii.encode(p.b64)).toRadixString(16).padLeft(4, '0'),
      );
    });
  });

  group('Z64 body', () {
    test('inflates back to the packed bitmap with a valid CRC', () {
      final body = z64GraphicBody(['FFFF', 'FFFF', '0000', '0000']);
      final p = _parseBody(body);
      expect(p.tag, 'Z64');
      final inflated = const ZLibDecoder().decodeBytes(base64.decode(p.b64));
      expect(inflated, [0xFF, 0xFF, 0xFF, 0xFF, 0, 0, 0, 0]);
      expect(
        p.crc,
        crc16Xmodem(ascii.encode(p.b64)).toRadixString(16).padLeft(4, '0'),
      );
    });

    test('is much smaller than raw hex on a repetitive bitmap', () {
      final rows = List.filled(200, 'FF' * 50); // 400x200 solid black
      final hex = rawHexGraphicBody(rows).length;
      final z64 = z64GraphicBody(rows).length;
      expect(z64, lessThan(hex ~/ 10));
    });
  });

  group('command headers', () {
    test('~DG keeps byte counts and appends the Z64 body', () {
      final zpl = ZplImageDownload(
        image: png,
        ditheringAlgorithm: ZplDitheringAlgorithm.threshold,
        compression: ZplImageCompression.z64,
      ).toZpl(const ZplConfiguration());
      expect(zpl, startsWith('~DGIMG,32,2,:Z64:'));
      expect(zpl, matches(RegExp(r':[0-9a-f]{4}$')));
    });

    test('^GFA with b64 keeps totalBytes twice and bytesPerRow', () {
      final zpl = ZplImageInline(
        image: png,
        ditheringAlgorithm: ZplDitheringAlgorithm.threshold,
        compression: ZplImageCompression.b64,
      ).toZpl(const ZplConfiguration());
      expect(zpl, contains('^GFA,32,32,2,:B64:'));
      expect(zpl, endsWith('^FS\n'));
    });

    test('^GFA default (acs) output is unchanged from 2.0', () {
      final inline = ZplImageInline(
        image: png,
        ditheringAlgorithm: ZplDitheringAlgorithm.threshold,
      );
      final legacy = StringBuffer()
        ..writeln('^FO0,0')
        ..write('^GFA,32,32,2,')
        ..write(inline.acsEncode(inline.monochromeHexRows()))
        ..writeln('^FS');
      expect(inline.toZpl(const ZplConfiguration()), legacy.toString());
    });

    test('^GFA with compression none emits raw hex rows', () {
      final zpl = ZplImageInline(
        image: png,
        ditheringAlgorithm: ZplDitheringAlgorithm.threshold,
        compression: ZplImageCompression.none,
      ).toZpl(const ZplConfiguration());
      expect(zpl, contains('^GFA,32,32,2,FFFF\n'));
      expect(zpl, contains('0000\n^FS'));
    });

    test('~DG none body is newline-separated hex rows (2.0 format)', () {
      final zpl = ZplImageDownload(
        image: png,
        ditheringAlgorithm: ZplDitheringAlgorithm.threshold,
      ).toZpl(const ZplConfiguration());
      expect(zpl, startsWith('~DGIMG,32,2,FFFF\n'));
      expect(zpl, endsWith('0000\n'));
    });
  });
}
