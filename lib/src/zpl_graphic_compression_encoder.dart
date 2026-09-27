import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

/// Body encoders for `~DG` / `^GFA` graphic data.
///
/// Zebra firmware accepts four bodies after the header counts:
/// - raw ASCII hex (2 chars per byte),
/// - ACS run-length hex (see `ImagePayloadBuilder.acsEncode`),
/// - `:B64:<base64>:<crc>` — base64 of the packed 1-bpp bitmap,
/// - `:Z64:<base64>:<crc>` — base64 of the zlib-deflated bitmap.
///
/// `package:archive` is used for deflate so the same code runs on web,
/// where `dart:io`'s `ZLibCodec` is unavailable.
///
/// Package-internal: not re-exported from the barrel.

/// CRC-16 as used by Zebra for `:B64:`/`:Z64:` bodies: polynomial 0x1021,
/// initial value 0x0000, no input/output reflection, no final XOR (the
/// XMODEM variant). Matches the reference `zpl-image` implementation.
/// Check vector: `'123456789'` → `0x31C3`.
int crc16Xmodem(List<int> bytes) {
  int crc = 0;
  for (final b in bytes) {
    crc ^= (b & 0xFF) << 8;
    for (int i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) : (crc << 1);
      crc &= 0xFFFF;
    }
  }
  return crc;
}

/// Packs monochrome hex rows (2 hex chars per byte, one string per row)
/// into the raw 1-bpp bitmap bytes the printer expects.
Uint8List packHexRows(List<String> rows) {
  if (rows.isEmpty) return Uint8List(0);
  final bytesPerRow = rows.first.length ~/ 2;
  final out = Uint8List(bytesPerRow * rows.length);
  int o = 0;
  for (final row in rows) {
    for (int i = 0; i + 1 < row.length; i += 2) {
      out[o++] = int.parse(row.substring(i, i + 2), radix: 16);
    }
  }
  return out;
}

/// Raw ASCII hex body: one row per line (newlines are ignored by the
/// printer and keep the output diff-friendly).
String rawHexGraphicBody(List<String> rows) => rows.map((r) => '$r\n').join();

/// `:B64:` body — base64 of the packed bitmap plus CRC-16 of the base64 text.
String b64GraphicBody(List<String> rows) =>
    _wrap('B64', base64.encode(packHexRows(rows)));

/// `:Z64:` body — base64 of the zlib-deflated bitmap plus CRC-16 of the
/// base64 text. Typically 70–90 % smaller than raw hex for logos and text.
String z64GraphicBody(List<String> rows, {int level = 9}) {
  final deflated = const ZLibEncoder().encodeBytes(
    packHexRows(rows),
    level: level,
  );
  return _wrap('Z64', base64.encode(deflated));
}

String _wrap(String tag, String b64) {
  final crc = crc16Xmodem(ascii.encode(b64));
  return ':$tag:$b64:${crc.toRadixString(16).padLeft(4, '0')}';
}
