import 'dart:typed_data';
import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'zpl_image_enums.dart';
import 'package:image/image.dart' as img;

export 'zpl_image_enums.dart';

/// A class to handle image-related commands, primarily for downloading graphics (~DG).
class ZplImage extends ZplCommand {
  /// The x-axis position of the image.
  final int x;

  /// The y-axis position of the image.
  final int y;

  /// The image data as a byte list.
  final Uint8List image;

  /// The name of the graphic to store and reference.
  final String graphicName;

  /// Optional target width to resize the image.
  final int? targetWidth;

  /// Optional target height to resize the image.
  final int? targetHeight;

  /// Maintains the aspect ratio when resizing. Default is true.
  final bool maintainAspect;

  /// The algorithm used to convert the image to monochrome.
  final ZplDitheringAlgorithm ditheringAlgorithm;

  /// The compression algorithm to reduce the transmitted ZPL payload size.
  final ZplImageCompression compression;

  const ZplImage({
    this.x = 0,
    this.y = 0,
    required this.image,
    this.graphicName = 'IMG',
    this.targetWidth,
    this.targetHeight,
    this.maintainAspect = true,
    this.ditheringAlgorithm = ZplDitheringAlgorithm.floydSteinberg,
    this.compression = ZplImageCompression.none,
  });

  int get width => targetWidth ?? (img.decodeImage(image)?.width ?? 0);
  int get height => targetHeight ?? (img.decodeImage(image)?.height ?? 0);

  @override
  String toZpl(ZplConfiguration context) {
    var decodedImage = img.decodeImage(image);
    if (decodedImage == null) {
      return ''; // Return empty string if image can't be decoded
    }

    if (targetWidth != null || targetHeight != null) {
      decodedImage = img.copyResize(
        decodedImage,
        width: targetWidth,
        height: targetHeight,
        maintainAspect: maintainAspect,
      );
    }

    final imgWidth = decodedImage.width;
    final imgHeight = decodedImage.height;
    final widthBytes = (imgWidth / 8).ceil();
    final totalBytes = widthBytes * imgHeight;

    final hexRows = _toMonochromeHexRows(decodedImage);

    if (compression == ZplImageCompression.acs) {
      return _toCompressedZpl(hexRows, totalBytes, widthBytes);
    } else {
      return _toUncompressedZpl(hexRows, totalBytes, widthBytes);
    }
  }

  String _toUncompressedZpl(
    List<String> hexRows,
    int totalBytes,
    int widthBytes,
  ) {
    final sb = StringBuffer();

    // Download graphic command
    sb.write('~DG$graphicName,${totalBytes.toInt()},${widthBytes.toInt()},');
    for (final row in hexRows) {
      sb.writeln(row);
    }

    // Position and print the graphic
    sb.writeln('^FO$x,$y');
    sb.writeln('^XG$graphicName,1,1^FS');

    return sb.toString();
  }

  String _toCompressedZpl(
    List<String> hexRows,
    int totalBytes,
    int widthBytes,
  ) {
    final sb = StringBuffer();
    sb.writeln('^FO$x,$y');
    sb.write('^GFA,$totalBytes,$totalBytes,$widthBytes,');

    String? previousRow;
    for (final row in hexRows) {
      if (row == previousRow) {
        sb.writeln(':'); // ZPL ACS duplicate row
      } else {
        sb.writeln(_compressRow(row));
        previousRow = row;
      }
    }
    sb.writeln('^FS');

    return sb.toString();
  }

  String _compressRow(String hexRow) {
    final sb = StringBuffer();
    int i = 0;

    // Check for trailing zeros or Fs
    final allZeros = RegExp(r'^0+$');
    final allFs = RegExp(r'^F+$');
    if (allZeros.hasMatch(hexRow)) return ',';
    if (allFs.hasMatch(hexRow)) return '!';

    while (i < hexRow.length) {
      final char = hexRow[i];
      int count = 1;

      while (i + count < hexRow.length && hexRow[i + count] == char) {
        count++;
      }

      final originalCount = count;

      while (count > 0) {
        if (count >= 20) {
          int multiples = (count ~/ 20).clamp(1, 20);
          sb.write(String.fromCharCode('g'.codeUnitAt(0) - 1 + multiples));
          count -= multiples * 20;
        } else if (count >= 2) {
          sb.write(String.fromCharCode('G'.codeUnitAt(0) - 2 + count));
          count = 0;
        } else {
          count = 0;
        }
      }
      sb.write(char);
      i += originalCount;
    }

    // Attempt to end with a comma (fill resting line with zeros) or exc. mark (Fs) if applicable
    String result = sb.toString();
    if (result.endsWith('0') && result.length >= 2) {
      // Find where trailing zeroes start
      int lastNonZero = result.lastIndexOf(RegExp(r'[1-9A-Ea-z]'));
      if (lastNonZero != -1 && lastNonZero < result.length - 2) {
        // Strip out the zero repetition encoding and just use comma
        // E.g., 'K0' -> ',' at end.
        final trailingZerosMatch = RegExp(r'[g-zG-Y]*0+$').firstMatch(result);
        if (trailingZerosMatch != null) {
          result = '${result.substring(0, trailingZerosMatch.start)},';
        }
      }
    } else if (result.endsWith('F') && result.length >= 2) {
      final trailingFsMatch = RegExp(r'[g-zG-Y]*F+$').firstMatch(result);
      if (trailingFsMatch != null) {
        result = '${result.substring(0, trailingFsMatch.start)}!';
      }
    }

    return result;
  }

  Float32List? _generateLuminanceMap(img.Image src) {
    if (ditheringAlgorithm == ZplDitheringAlgorithm.threshold) return null;

    final srcWidth = src.width;
    final srcHeight = src.height;
    final luminanceMap = Float32List(srcWidth * srcHeight);

    for (int y = 0; y < srcHeight; y++) {
      for (int x = 0; x < srcWidth; x++) {
        luminanceMap[y * srcWidth + x] = img
            .getLuminance(src.getPixel(x, y))
            .toDouble();
      }
    }

    for (int y = 0; y < srcHeight; y++) {
      for (int x = 0; x < srcWidth; x++) {
        final int index = y * srcWidth + x;
        final double oldPixel = luminanceMap[index];
        final double newPixel = oldPixel < 128.0 ? 0.0 : 255.0;
        luminanceMap[index] = newPixel;
        final double quantError = oldPixel - newPixel;

        if (ditheringAlgorithm == ZplDitheringAlgorithm.floydSteinberg) {
          if (x + 1 < srcWidth) {
            luminanceMap[index + 1] += quantError * 7 / 16;
          }
          if (y + 1 < srcHeight) {
            if (x - 1 >= 0) {
              luminanceMap[(y + 1) * srcWidth + (x - 1)] += quantError * 3 / 16;
            }
            luminanceMap[(y + 1) * srcWidth + x] += quantError * 5 / 16;
            if (x + 1 < srcWidth) {
              luminanceMap[(y + 1) * srcWidth + (x + 1)] += quantError * 1 / 16;
            }
          }
        } else if (ditheringAlgorithm == ZplDitheringAlgorithm.atkinson) {
          final double fraction = quantError / 8.0;
          if (x + 1 < srcWidth) luminanceMap[index + 1] += fraction;
          if (x + 2 < srcWidth) luminanceMap[index + 2] += fraction;
          if (y + 1 < srcHeight) {
            if (x - 1 >= 0) {
              luminanceMap[(y + 1) * srcWidth + (x - 1)] += fraction;
            }
            luminanceMap[(y + 1) * srcWidth + x] += fraction;
            if (x + 1 < srcWidth) {
              luminanceMap[(y + 1) * srcWidth + (x + 1)] += fraction;
            }
          }
          if (y + 2 < srcHeight) {
            luminanceMap[(y + 2) * srcWidth + x] += fraction;
          }
        }
      }
    }
    return luminanceMap;
  }

  /// Public wrapper to retrieve monochrome boolean pixels suitable for offline canvas rendering.
  /// Returns a record of (width, height, pixels) where true is a black dot.
  ({int width, int height, List<bool> pixels})? getMonochromePixels() {
    var decodedImage = img.decodeImage(image);
    if (decodedImage == null) return null;

    if (targetWidth != null || targetHeight != null) {
      decodedImage = img.copyResize(
        decodedImage,
        width: targetWidth,
        height: targetHeight,
        maintainAspect: maintainAspect,
      );
    }

    final srcWidth = decodedImage.width;
    final srcHeight = decodedImage.height;
    final luminanceMap = _generateLuminanceMap(decodedImage);

    final pixels = List<bool>.filled(srcWidth * srcHeight, false);
    for (int h = 0; h < srcHeight; h++) {
      for (int w = 0; w < srcWidth; w++) {
        if (luminanceMap != null) {
          pixels[h * srcWidth + w] = luminanceMap[h * srcWidth + w] < 128.0;
        } else {
          final pixel = decodedImage.getPixel(w, h);
          pixels[h * srcWidth + w] = img.getLuminance(pixel) < 128;
        }
      }
    }
    return (width: srcWidth, height: srcHeight, pixels: pixels);
  }

  /// Converts an image to a list of ZPL-compatible monochrome hexadecimal string rows.
  List<String> _toMonochromeHexRows(img.Image src) {
    final srcWidth = src.width;
    final srcHeight = src.height;

    final Float32List? luminanceMap = _generateLuminanceMap(src);

    final rows = <String>[];

    for (int h = 0; h < srcHeight; h++) {
      final rowSb = StringBuffer();
      var byte = 0;
      var bit = 0;
      for (int w = 0; w < srcWidth; w++) {
        bool isBlack;
        if (luminanceMap != null) {
          isBlack = luminanceMap[h * srcWidth + w] < 128.0;
        } else {
          final pixel = src.getPixel(w, h);
          isBlack = img.getLuminance(pixel) < 128;
        }

        if (isBlack) {
          byte |= (1 << (7 - bit));
        }

        bit++;
        if (bit == 8) {
          rowSb.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
          byte = 0;
          bit = 0;
        }
      }

      // Write any remaining bits
      if (bit > 0) {
        rowSb.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
      }
      rows.add(rowSb.toString());
    }

    return rows;
  }

  @override
  int calculateWidth(ZplConfiguration config) {
    return width;
  }
}
