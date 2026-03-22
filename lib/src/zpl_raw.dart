import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// A command that outputs raw ZPL string directly without any processing.
///
/// Use this to inject any ZPL command that is not natively supported by the
/// flutter_zpl_generator library.
class ZplRaw extends ZplCommand {
  /// The raw ZPL command string to output.
  final String command;

  const ZplRaw({required this.command});

  @override
  String toZpl(ZplConfiguration context) => '$command\n';

  @override
  int calculateWidth(ZplConfiguration config) => 0;
}
