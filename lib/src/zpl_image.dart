import 'dart:typed_data';
import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'package:image/image.dart' as img;

/// Represents the algorithm used to convert continuous-tone images to monochrome.
enum ZplDitheringAlgorithm {
  /// Simple thresholding: pixels with luminance < 128 become black.
  /// Result: Hard separations between black and white, zero gradients.
  threshold,

  /// Floyd-Steinberg dithering: disperses error to neighboring pixels.
  /// Result: Smooth distributions of dots creating natural-looking gradients.
  floydSteinberg,

  /// Atkinson dithering: disperses error to a further range of neighboring pixels.
  /// Result: High contrast, distinct "newspaper print" dot patterns without washing out.
  atkinson,
}

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

  const ZplImage({
    this.x = 0,
    this.y = 0,
    required this.image,
    this.graphicName = 'IMG',
    this.targetWidth,
    this.targetHeight,
    this.maintainAspect = true,
    this.ditheringAlgorithm = ZplDitheringAlgorithm.floydSteinberg,
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

    final sb = StringBuffer();

    // Download graphic command
    sb.write('~DG$graphicName,${totalBytes.toInt()},${widthBytes.toInt()},');
    final hexString = _toMonochromeHex(decodedImage);
    sb.writeln(hexString);

    // Position and print the graphic
    sb.writeln('^FO$x,$y');
    sb.writeln('^XG$graphicName,1,1^FS');

    return sb.toString();
  }

  /// Converts an image to a ZPL-compatible monochrome hexadecimal string.
  String _toMonochromeHex(img.Image src) {
    final sb = StringBuffer();
    final srcWidth = src.width;
    final srcHeight = src.height;

    Float32List? luminanceMap;
    if (ditheringAlgorithm != ZplDitheringAlgorithm.threshold) {
      luminanceMap = Float32List(srcWidth * srcHeight);
      for (int y = 0; y < srcHeight; y++) {
        for (int x = 0; x < srcWidth; x++) {
          luminanceMap[y * srcWidth + x] = img.getLuminance(src.getPixel(x, y)).toDouble();
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
              if (x - 1 >= 0) luminanceMap[(y + 1) * srcWidth + (x - 1)] += fraction;
              luminanceMap[(y + 1) * srcWidth + x] += fraction;
              if (x + 1 < srcWidth) luminanceMap[(y + 1) * srcWidth + (x + 1)] += fraction;
            }
            if (y + 2 < srcHeight) {
              luminanceMap[(y + 2) * srcWidth + x] += fraction;
            }
          }
        }
      }
    }

    for (int h = 0; h < srcHeight; h++) {
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
          sb.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
          byte = 0;
          bit = 0;
        }
      }

      // Write any remaining bits
      if (bit > 0) {
        sb.write(byte.toRadixString(16).padLeft(2, '0').toUpperCase());
      }
      sb.writeln(); // Newline for each row
    }

    return sb.toString();
  }

  @override
  int calculateWidth(ZplConfiguration config) {
    return width;
  }
}
