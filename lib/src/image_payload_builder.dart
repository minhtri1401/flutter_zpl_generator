import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'zpl_image_enums.dart';

/// Shared image pipeline mixin for [ZplImageDownload] and [ZplImageInline].
///
/// Mixers provide the five abstract getters below; the mixin caches decode
/// + resize + monochrome hex-row results per-instance so repeated
/// `width`/`height` reads and a single `toZpl` call don't redo the
/// expensive work.
///
/// Package-internal: lives under `lib/src/` and is NOT re-exported from the
/// package barrel. Other `lib/src/` files import via relative path. Tests
/// within the same package may reach in via
/// `package:flutter_zpl_generator/src/image_payload_builder.dart`.
mixin ImagePayloadBuilder {
  Uint8List get image;
  int? get targetWidth;
  int? get targetHeight;
  bool get maintainAspect;
  ZplDitheringAlgorithm get ditheringAlgorithm;

  img.Image? _cachedDecode;
  img.Image? _cachedResized;
  List<String>? _cachedHexRows;

  /// Decoded source image, memoised.
  img.Image? decodedImage() => _cachedDecode ??= img.decodeImage(image);

  /// Resized image (or the decoded original when no target is set), memoised.
  img.Image? resizedImage() {
    if (_cachedResized != null) return _cachedResized;
    final d = decodedImage();
    if (d == null) return null;
    if (targetWidth == null && targetHeight == null) {
      _cachedResized = d;
    } else {
      _cachedResized = img.copyResize(
        d,
        width: targetWidth,
        height: targetHeight,
        maintainAspect: maintainAspect,
      );
    }
    return _cachedResized;
  }

  /// Post-resize width in dots (Bug 2 fix: reflects aspect-scaled dims).
  int get renderedWidth => resizedImage()?.width ?? 0;

  /// Post-resize height in dots (Bug 2 fix).
  int get renderedHeight => resizedImage()?.height ?? 0;

  /// Bytes per row in the packed 1bpp monochrome bitmap.
  int get widthBytes => (renderedWidth / 8).ceil();

  /// Total bytes for the packed bitmap.
  int get totalBytes => widthBytes * renderedHeight;

  /// Monochrome hex rows (one ASCII string per row). Cached.
  List<String> monochromeHexRows() {
    if (_cachedHexRows != null) return _cachedHexRows!;
    final r = resizedImage();
    if (r == null) {
      _cachedHexRows = const [];
      return _cachedHexRows!;
    }
    _cachedHexRows = _encodeHexRows(r);
    return _cachedHexRows!;
  }

  /// Offline-preview helper — monochrome pixel grid (true = black dot).
  ({int width, int height, List<bool> pixels})? monochromePixels() {
    final r = resizedImage();
    if (r == null) return null;
    final lum = _generateLuminanceMap(r);
    final pixels = List<bool>.filled(r.width * r.height, false);
    for (int h = 0; h < r.height; h++) {
      for (int w = 0; w < r.width; w++) {
        if (lum != null) {
          pixels[h * r.width + w] = lum[h * r.width + w] < 128.0;
        } else {
          pixels[h * r.width + w] = img.getLuminance(r.getPixel(w, h)) < 128;
        }
      }
    }
    return (width: r.width, height: r.height, pixels: pixels);
  }

  Float32List? _generateLuminanceMap(img.Image src) {
    if (ditheringAlgorithm == ZplDitheringAlgorithm.threshold) return null;
    final sw = src.width, sh = src.height;
    final map = Float32List(sw * sh);
    for (int y = 0; y < sh; y++) {
      for (int x = 0; x < sw; x++) {
        map[y * sw + x] = img.getLuminance(src.getPixel(x, y)).toDouble();
      }
    }
    for (int y = 0; y < sh; y++) {
      for (int x = 0; x < sw; x++) {
        final i = y * sw + x;
        final oldPx = map[i];
        final newPx = oldPx < 128.0 ? 0.0 : 255.0;
        map[i] = newPx;
        final err = oldPx - newPx;
        if (ditheringAlgorithm == ZplDitheringAlgorithm.floydSteinberg) {
          if (x + 1 < sw) map[i + 1] += err * 7 / 16;
          if (y + 1 < sh) {
            if (x - 1 >= 0) map[(y + 1) * sw + (x - 1)] += err * 3 / 16;
            map[(y + 1) * sw + x] += err * 5 / 16;
            if (x + 1 < sw) map[(y + 1) * sw + (x + 1)] += err * 1 / 16;
          }
        } else if (ditheringAlgorithm == ZplDitheringAlgorithm.atkinson) {
          final f = err / 8.0;
          if (x + 1 < sw) map[i + 1] += f;
          if (x + 2 < sw) map[i + 2] += f;
          if (y + 1 < sh) {
            if (x - 1 >= 0) map[(y + 1) * sw + (x - 1)] += f;
            map[(y + 1) * sw + x] += f;
            if (x + 1 < sw) map[(y + 1) * sw + (x + 1)] += f;
          }
          if (y + 2 < sh) map[(y + 2) * sw + x] += f;
        }
      }
    }
    return map;
  }

  List<String> _encodeHexRows(img.Image src) {
    final sw = src.width, sh = src.height;
    final lum = _generateLuminanceMap(src);
    final rows = <String>[];
    for (int h = 0; h < sh; h++) {
      final sb = StringBuffer();
      int byte = 0, bit = 0;
      for (int w = 0; w < sw; w++) {
        final isBlack = lum != null
            ? lum[h * sw + w] < 128.0
            : img.getLuminance(src.getPixel(w, h)) < 128;
        if (isBlack) byte |= (1 << (7 - bit));
        bit++;
        if (bit == 8) {
          sb.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
          byte = 0;
          bit = 0;
        }
      }
      if (bit > 0) {
        sb.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
      }
      rows.add(sb.toString());
    }
    return rows;
  }

  /// ACS-encodes a list of hex rows, with `:` shortcut for duplicate rows.
  /// Caller is responsible for emitting the `^GFA`/`~DG` header.
  String acsEncode(List<String> rows) {
    final sb = StringBuffer();
    String? prev;
    for (final row in rows) {
      if (row == prev) {
        sb.writeln(':');
      } else {
        sb.writeln(compressRow(row));
        prev = row;
      }
    }
    return sb.toString();
  }

  /// ACS run-length encode a single hex row. Exposed as package-internal
  /// API for the Phase 06 encoder audit tests.
  String compressRow(String hexRow) {
    final sb = StringBuffer();
    int i = 0;
    final allZeros = RegExp(r'^0+$');
    final allFs = RegExp(r'^F+$');
    if (allZeros.hasMatch(hexRow)) return ',';
    if (allFs.hasMatch(hexRow)) return '!';
    while (i < hexRow.length) {
      final ch = hexRow[i];
      int count = 1;
      while (i + count < hexRow.length && hexRow[i + count] == ch) {
        count++;
      }
      final original = count;
      while (count > 0) {
        if (count >= 20) {
          final multiples = (count ~/ 20).clamp(1, 20);
          sb.write(String.fromCharCode('g'.codeUnitAt(0) - 1 + multiples));
          count -= multiples * 20;
        } else if (count >= 2) {
          sb.write(String.fromCharCode('G'.codeUnitAt(0) - 2 + count));
          count = 0;
        } else {
          count = 0;
        }
      }
      sb.write(ch);
      i += original;
    }
    String result = sb.toString();
    if (result.endsWith('0') && result.length >= 2) {
      final lastNonZero = result.lastIndexOf(RegExp(r'[1-9A-Ea-z]'));
      if (lastNonZero != -1 && lastNonZero < result.length - 2) {
        final m = RegExp(r'[g-zG-Y]*0+$').firstMatch(result);
        if (m != null) result = '${result.substring(0, m.start)},';
      }
    } else if (result.endsWith('F') && result.length >= 2) {
      final m = RegExp(r'[g-zG-Y]*F+$').firstMatch(result);
      if (m != null) result = '${result.substring(0, m.start)}!';
    }
    return result;
  }
}
