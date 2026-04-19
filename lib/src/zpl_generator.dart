import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// The main class that aggregates a list of ZPL commands and generates the
/// final, printable ZPL script string.
///
/// Configuration is provided directly via [config] and passed as context to
/// all commands, eliminating the need for a separate configuration command
/// in the command list.
///
/// v2.0 note: font uploads are now first-class commands ([ZplFontUpload])
/// that you pass inline in [commands]. The two-phase build partitioning
/// (control commands before `^XA`) is introduced in the Phase 05 edit.
class ZplGenerator {
  /// Global label configuration (dimensions, density, darkness, etc.).
  final ZplConfiguration config;

  /// A list of [ZplCommand] objects that make up the label.
  final List<ZplCommand> commands;

  ZplGenerator({
    this.config = const ZplConfiguration(),
    required this.commands,
  });

  /// Builds the complete ZPL script.
  ///
  /// Wraps all commands with `^XA` / `^XZ`, then emits the configuration
  /// and all label commands.
  Future<String> build() async {
    final sb = StringBuffer();
    sb.writeln('^XA');
    sb.write(config.toZpl());

    for (final command in commands) {
      sb.write(command.toZpl(config));
    }

    sb.writeln('^XZ');
    return sb.toString();
  }
}
