import 'zpl_command_base.dart';
import 'enums.dart';

/// Represents global ZPL configuration settings for a label. This command is
/// typically placed at the beginning of a ZPL script to configure the printer's
/// behavior for the subsequent label.
class ZplConfiguration extends ZplCommand {
  /// The print darkness level. A value between 0 and 30.
  /// Corresponds to the `~SD` command.
  final int? darkness;

  /// The label length in dots.
  /// Corresponds to the `^LL` command.
  final int? labelLength;

  /// The x-axis position of the label home.
  /// Corresponds to the `^LH` command.
  final int? labelHomeX;

  /// The y-axis position of the label home.
  /// Corresponds to the `^LH` command.
  final int? labelHomeY;

  /// The print width in dots.
  /// Corresponds to the `^PW` command.
  final int? printWidth;

  /// The print speed. Values can range from 2 to 12 inches per second.
  /// Corresponds to the `^PR` command.
  final int? printSpeed;

  /// The print mode.
  /// Corresponds to the `^MM` command.
  final ZplPrintMode? printMode;

  /// The media type.
  /// Corresponds to the `^MT` command.
  final ZplMediaType? mediaType;

  /// Inverts the label format 180 degrees.
  /// Corresponds to the `^PO` command.
  final ZplPrintOrientation? printOrientation;

  /// The print density (resolution). This affects how content fits on the physical label.
  /// Higher DPI means smaller physical output (more dots per inch).
  /// Corresponds to the `^JM` command.
  /// - 152 DPI (6dpmm): Standard resolution
  /// - 203 DPI (8dpmm): Most common resolution
  /// - 300 DPI (12dpmm): High resolution
  /// - 600 DPI (24dpmm): Very high resolution
  final ZplPrintDensity? printDensity;

  /// The international character set for encoding. A value between 0 and 27.
  /// Corresponds to the `^CI` command.
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

  @override
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
