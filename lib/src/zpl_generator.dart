import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'zpl_column.dart';
import 'zpl_row.dart';
import 'zpl_text.dart';

/// The main class that aggregates a list of ZPL commands and generates the
/// final, printable ZPL script string.
class ZplGenerator {
  /// A list of [ZplCommand] objects that make up the label. The commands will
  /// be processed in the order they appear in the list.
  final List<ZplCommand> commands;

  ZplGenerator(this.commands);

  /// Builds the complete ZPL script.
  ///
  /// This method wraps the combined ZPL from all commands with the
  /// standard ZPL start (`^XA`) and end (`^XZ`) commands, making it ready
  /// to be sent to a Zebra printer.
  String build() {
    final sb = StringBuffer();
    sb.writeln('^XA');

    // First pass: find configuration and apply it to layout components
    ZplConfiguration? config;
    for (final command in commands) {
      if (command is ZplConfiguration) {
        config = command;
        break;
      }
    }

    // Second pass: apply configuration context to layout components
    if (config != null) {
      _applyConfigurationToLayouts(commands, config);
    }

    // Third pass: generate ZPL
    for (final command in commands) {
      sb.write(command.toZpl());
    }

    sb.writeln('^XZ');
    return sb.toString();
  }

  /// Recursively apply configuration context to layout components
  void _applyConfigurationToLayouts(
    List<ZplCommand> commands,
    ZplConfiguration config,
  ) {
    for (final command in commands) {
      if (command is ZplColumn) {
        command.setConfiguration(config);
        // Also apply to nested children recursively
        _applyConfigurationToLayouts(command.children, config);
      } else if (command is ZplRow) {
        command.setConfiguration(config);
        // Also apply to nested children recursively
        _applyConfigurationToLayouts(command.children, config);
      } else if (command is ZplText) {
        command.setConfiguration(config);
      }
    }
  }
}
