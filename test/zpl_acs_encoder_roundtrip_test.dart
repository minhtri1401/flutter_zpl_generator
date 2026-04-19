import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
// ImagePayloadBuilder is package-internal (not in the barrel).
// Tests within the same package may reach into src/.
import 'package:flutter_zpl_generator/src/image_payload_builder.dart';

/// Minimal inverse of ImagePayloadBuilder.compressRow — for test use only.
/// Given the full row-byte count, reconstructs the original hex row from an
/// encoded fragment. Handles:
/// - the `,` (fill zeros to row end) and `!` (fill Fs to row end) shortcuts.
/// - repeat codes G..Y (2..20) and g..z (20..400) followed by a single hex char.
String acsDecode(String encoded, int rowBytes) {
  final fullLen = rowBytes * 2;
  if (encoded == ',') return '0' * fullLen;
  if (encoded == '!') return 'F' * fullLen;

  final sb = StringBuffer();
  int i = 0;
  while (i < encoded.length) {
    // Accumulate one run-length across any number of G..Y / g..z codes.
    int runLen = 1;
    bool sawRepeat = false;
    while (i < encoded.length) {
      final ch = encoded[i];
      final code = ch.codeUnitAt(0);
      if (code >= 'G'.codeUnitAt(0) && code <= 'Y'.codeUnitAt(0)) {
        if (!sawRepeat) runLen = 0;
        runLen += code - 'G'.codeUnitAt(0) + 2;
        sawRepeat = true;
        i++;
      } else if (code >= 'g'.codeUnitAt(0) && code <= 'z'.codeUnitAt(0)) {
        if (!sawRepeat) runLen = 0;
        runLen += (code - 'g'.codeUnitAt(0) + 1) * 20;
        sawRepeat = true;
        i++;
      } else {
        break;
      }
    }
    if (i >= encoded.length) break;
    final data = encoded[i];
    i++;
    if (data == ',') {
      while (sb.length < fullLen) {
        sb.write('0');
      }
      return sb.toString();
    }
    if (data == '!') {
      while (sb.length < fullLen) {
        sb.write('F');
      }
      return sb.toString();
    }
    for (int k = 0; k < runLen; k++) {
      sb.write(data);
    }
  }
  while (sb.length < fullLen) {
    sb.write('0');
  }
  return sb.toString();
}

/// Host class that mixes in ImagePayloadBuilder so tests can reach
/// compressRow / acsEncode without needing an actual image.
class _EncoderHost with ImagePayloadBuilder {
  @override
  final Uint8List image = Uint8List(0);
  @override
  final int? targetWidth = null;
  @override
  final int? targetHeight = null;
  @override
  final bool maintainAspect = true;
  @override
  final ZplDitheringAlgorithm ditheringAlgorithm =
      ZplDitheringAlgorithm.threshold;
}

void main() {
  final host = _EncoderHost();

  group('ACS compressRow — fixture round-trip', () {
    final fixtures = <String, int>{
      '0000000000000000': 8,
      'FFFFFFFFFFFFFFFF': 8,
      '55AA55AA55AA55AA': 8,
      'F0F0F0F0F0F0F0F0': 8,
      '0F0F0F0F0F0F0F0F': 8,
      '1234567890ABCDEF': 8,
    };

    fixtures.forEach((row, bytes) {
      test('round-trips "$row"', () {
        final encoded = host.compressRow(row);
        final decoded = acsDecode(encoded, bytes);
        expect(decoded, row, reason: 'encoded="$encoded"');
      });
    });
  });

  group('ACS compressRow — boundary run lengths', () {
    for (final count in [1, 2, 19, 20, 21, 39, 40, 399, 400, 401]) {
      test('run of $count × "1" round-trips', () {
        final row = '1' * count;
        final bytes = (count / 2).ceil();
        final encoded = host.compressRow(row);
        final decoded = acsDecode(encoded, bytes);
        expect(decoded.substring(0, count), row,
            reason: 'encoded="$encoded"');
      });
    }
  });

  group('ACS compressRow — fuzz', () {
    test('1000 random 72-byte rows round-trip', () {
      final rng = Random(0xC0FFEE);
      const bytes = 72;
      const hexLen = bytes * 2;
      const hexChars = '0123456789ABCDEF';
      int failures = 0;
      for (int k = 0; k < 1000; k++) {
        final sb = StringBuffer();
        for (int j = 0; j < hexLen; j++) {
          sb.write(hexChars[rng.nextInt(16)]);
        }
        final row = sb.toString();
        final encoded = host.compressRow(row);
        final decoded = acsDecode(encoded, bytes);
        if (decoded != row) {
          failures++;
          if (failures < 5) {
            // ignore: avoid_print
            print('FUZZ MISMATCH:\n  in=$row\n  enc=$encoded\n  out=$decoded');
          }
        }
      }
      expect(failures, 0);
    });
  });

  group('ACS acsEncode — multi-row with duplicate shortcut', () {
    test('two identical rows produce a ":" shortcut on the second', () {
      const row = '55AA55AA';
      final out = host.acsEncode([row, row]);
      expect(out.split('\n')[1].trim(), ':');
    });
  });
}
