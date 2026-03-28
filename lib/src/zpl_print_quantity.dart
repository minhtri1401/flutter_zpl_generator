import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// Represents the ^PQ (Print Quantity) command.
///
/// This command gives control over several printing operations.
/// It must be placed in a format before the ^XZ command.
class ZplPrintQuantity extends ZplCommand {
  /// Total quantity of labels to print. (1 - 99999999)
  final int quantity;

  /// Number of labels to print between printer pauses.
  /// (0 = no pause)
  final int? pauseInterval;

  /// Number of replicates of each serial number.
  /// Used in conjunction with serialization (^SN).
  final int? replicatesPerSerial;

  /// Override pause count.
  /// true = cut but no pause.
  final bool overridePause;

  /// Cut on RFID void.
  /// true = cut after voided RFID label.
  final bool cutOnRfidVoid;

  /// Creates a ZPL command to set print quantity and related operations.
  const ZplPrintQuantity({
    required this.quantity,
    this.pauseInterval,
    this.replicatesPerSerial,
    this.overridePause = false,
    this.cutOnRfidVoid = false,
  }) : assert(
         quantity >= 1 && quantity <= 99999999,
         'Quantity must be between 1 and 99999999',
       );

  @override
  String toZpl(ZplConfiguration context) {
    String zpl = '^PQ$quantity';

    // To prevent sending unnecessary parameters, we only append commas
    // if subsequent parameters have non-default/explicitly specified values.
    if (pauseInterval != null ||
        replicatesPerSerial != null ||
        overridePause ||
        cutOnRfidVoid) {
      zpl += ',${pauseInterval ?? 0}';

      if (replicatesPerSerial != null || overridePause || cutOnRfidVoid) {
        zpl += ',${replicatesPerSerial ?? 0}';

        if (overridePause || cutOnRfidVoid) {
          zpl += ',${overridePause ? 'Y' : 'N'}';

          if (cutOnRfidVoid) {
            zpl += ',${cutOnRfidVoid ? 'Y' : 'N'}';
          }
        }
      }
    }

    return zpl;
  }

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}
