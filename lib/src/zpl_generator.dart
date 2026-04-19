import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'zpl_image_download.dart';

/// Aggregates a list of [ZplCommand] instances and generates the final
/// ZPL script string.
///
/// v2.0 emission model:
/// 1. All [ZplControlCommand]s (tilde-prefixed: `~DG`, `~DY`, …) are flushed
///    in original order BEFORE `^XA`. Required by strict Link-OS firmware
///    (ZQ620 etc.) and recommended by Zebra on all firmware.
/// 2. `^XA` opens the active format.
/// 3. [config] is serialised (`^LL`, `^PW`, `~SD`, …).
/// 4. If [autoLabelLengthFromFirstImage] is true and `config.labelLength`
///    is null, a `^LL` line matching the first [ZplImageDownload.height]
///    is emitted.
/// 5. All non-control commands are flushed in original order.
/// 6. `^XZ` closes the format.
class ZplGenerator {
  /// Global label configuration.
  final ZplConfiguration config;

  /// Commands making up the label. Order is preserved within each
  /// partition (control vs format).
  final List<ZplCommand> commands;

  /// When true and [commands] contains at least one [ZplImageDownload],
  /// emit `^LL<firstDownload.height>` inside the format so the printer
  /// feeds exactly the image height. No-op if [config].labelLength is
  /// already set — explicit config always wins.
  final bool autoLabelLengthFromFirstImage;

  ZplGenerator({
    this.config = const ZplConfiguration(),
    required this.commands,
    this.autoLabelLengthFromFirstImage = false,
  });

  /// Builds the complete ZPL script.
  Future<String> build() async {
    final sb = StringBuffer();

    // Phase 1 — control commands BEFORE ^XA.
    for (final cmd in commands) {
      if (cmd is ZplControlCommand) {
        sb.write(cmd.toZpl(config));
      }
    }

    // Phase 2 — format block.
    sb.writeln('^XA');
    sb.write(config.toZpl());

    if (autoLabelLengthFromFirstImage && config.labelLength == null) {
      final firstDownload =
          commands.whereType<ZplImageDownload>().firstOrNull;
      if (firstDownload != null) {
        sb.writeln('^LL${firstDownload.height}');
      }
    }

    for (final cmd in commands) {
      if (cmd is! ZplControlCommand) {
        sb.write(cmd.toZpl(config));
      }
    }

    sb.writeln('^XZ');
    return sb.toString();
  }
}
