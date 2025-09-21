import 'dart:typed_data';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:image/image.dart' as img;

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

  const ZplImage({
    this.x = 0,
    this.y = 0,
    required this.image,
    this.graphicName = 'IMG',
  });

  int get width => img.decodeImage(image)!.width;
  int get height => img.decodeImage(image)!.height;
  @override
  String toZpl() {
    final decodedImage = img.decodeImage(image);
    if (decodedImage == null) {
      return ''; // Return empty string if image can't be decoded
    }

    final width = decodedImage.width;
    final height = decodedImage.height;
    final widthBytes = (width / 8).ceil();
    final totalBytes = widthBytes * height;

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
    final width = src.width;
    final height = src.height;

    for (int h = 0; h < height; h++) {
      var byte = 0;
      var bit = 0;
      for (int w = 0; w < width; w++) {
        final pixel = src.getPixel(w, h);
        // A simple threshold for monochrome conversion
        final isBlack = img.getLuminance(pixel) < 128;

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
  int calculateWidth(ZplConfiguration? config) {
    return width;
  }
}
