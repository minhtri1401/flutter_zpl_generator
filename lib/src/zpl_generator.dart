import 'zpl_command_base.dart';

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

    for (final command in commands) {
      sb.write(command.toZpl());
    }

    sb.writeln('^XZ');
    return sb.toString();
  }
}
