import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// Represents the ^RS (RFID Setup) command.
///
/// This is required globally for Zebra RFID printers to position the reader
/// appropriately before invoking the ^RF command. It configures the tag type,
/// read/write positions, and void contingencies.
class ZplRfidSetup extends ZplCommand {
  /// The RFID tag type.
  /// Defaults to `8` which represents EPC Class 1 Gen 2.
  final int tagType;

  /// The read/write position setting.
  final String? readWritePosition;

  /// The void print length if the tag cannot be read.
  final int? voidPrintLength;

  /// Number of labels to print correctly before continuing.
  final int? labelsPerForm;

  /// Creates a ZPL command to setup RFID encoding.
  const ZplRfidSetup({
    this.tagType = 8, // By default EPC Gen 2
    this.readWritePosition,
    this.voidPrintLength,
    this.labelsPerForm,
  });

  @override
  String toZpl(ZplConfiguration context) {
    String zpl = '^RS$tagType';

    if (readWritePosition != null ||
        voidPrintLength != null ||
        labelsPerForm != null) {
      zpl += ',${readWritePosition ?? ''}';

      if (voidPrintLength != null || labelsPerForm != null) {
        zpl += ',${voidPrintLength ?? ''}';

        if (labelsPerForm != null) {
          zpl += ',$labelsPerForm';
        }
      }
    }

    return zpl;
  }

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}
