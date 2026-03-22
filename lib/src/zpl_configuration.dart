import 'enums.dart';

/// Represents global ZPL configuration settings for a label.
/// Passed as context to all commands via `toZpl(context)`.
class ZplConfiguration {
  /// The print darkness level. A value between 0 and 30.
  final int? darkness;

  /// The label length in dots.
  final int? labelLength;

  /// The x-axis position of the label home.
  final int? labelHomeX;

  /// The y-axis position of the label home.
  final int? labelHomeY;

  /// The print width in dots.
  final int? printWidth;

  /// The print speed. Values can range from 2 to 12 inches per second.
  final int? printSpeed;

  /// The print mode.
  final ZplPrintMode? printMode;

  /// The media type.
  final ZplMediaType? mediaType;

  /// Inverts the label format 180 degrees.
  final ZplPrintOrientation? printOrientation;

  /// The print density (resolution).
  final ZplPrintDensity? printDensity;

  /// The international character set for encoding. A value between 0 and 27.
  final int? internationalEncoding;

  const ZplConfiguration({
    this.darkness,
    this.labelLength,
    this.labelHomeX,
    this.labelHomeY,
    this.printWidth,
    this.printSpeed,
    this.printMode,
    this.mediaType,
    this.printOrientation,
    this.internationalEncoding,
    this.printDensity,
  });

  /// Generates the ZPL config commands (`~SD`, `^LL`, `^PW`, etc.).
  String toZpl() {
    final sb = StringBuffer();

    if (darkness != null) {
      sb.writeln('~SD${darkness.toString().padLeft(2, '0')}');
    }
    if (labelLength != null) {
      sb.writeln('^LL$labelLength');
    }
    if (labelHomeX != null && labelHomeY != null) {
      sb.writeln('^LH$labelHomeX,$labelHomeY');
    }
    if (printWidth != null) {
      sb.writeln('^PW$printWidth');
    }
    if (printSpeed != null) {
      sb.writeln('^PR$printSpeed');
    }
    if (printMode != null) {
      final mode = printMode!.name.substring(0, 1).toUpperCase();
      sb.writeln('^MM$mode');
    }
    if (mediaType != null) {
      final type = mediaType!.name.substring(0, 1).toUpperCase();
      sb.writeln('^MT$type');
    }
    if (printOrientation != null) {
      final orientation = printOrientation!.name.substring(0, 1).toUpperCase();
      sb.writeln('^PO$orientation');
    }
    if (printDensity != null) {
      sb.writeln('^JM${printDensity!.value}');
    }
    if (internationalEncoding != null) {
      sb.writeln('^CI$internationalEncoding');
    }

    return sb.toString();
  }
}
