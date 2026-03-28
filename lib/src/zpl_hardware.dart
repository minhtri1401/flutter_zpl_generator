import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// Starts an immediate Zebra Basic Interpreter (ZBI) script run directly
/// on the printer hardware OS.
///
/// Uses the `~JI` command. Returns width `0` for layout purposes.
class ZplZbiStart extends ZplCommand {
  /// The name or filesystem path of the ZBI program.
  final String path;

  /// Optional parameters passed to the ZBI program.
  final String? parameters;

  const ZplZbiStart({required this.path, this.parameters});

  @override
  int calculateWidth(ZplConfiguration config) => 0;

  @override
  String toZpl(ZplConfiguration config) {
    if (parameters != null && parameters!.isNotEmpty) {
      return '~JI$path,$parameters\n';
    }
    return '~JI$path\n';
  }
}

/// Aborts execution of any running Zebra Basic Interpreter (ZBI) script
/// immediately via the `~JQ` host command.
class ZplZbiStop extends ZplCommand {
  const ZplZbiStop();

  @override
  int calculateWidth(ZplConfiguration config) => 0;

  @override
  String toZpl(ZplConfiguration config) {
    return '~JQ\n';
  }
}

/// Triggers a Host Query (`~HQ`) response back over the printer port
/// (e.g. Serial or TCP) returning hardware diagnostic states.
class ZplHostQuery extends ZplCommand {
  /// The specific query type (e.g., 'ES' for maintenance, 'OD' for odometer).
  final String queryGroup;

  const ZplHostQuery({required this.queryGroup});

  @override
  int calculateWidth(ZplConfiguration config) => 0;

  @override
  String toZpl(ZplConfiguration config) {
    return '~HQ$queryGroup\n';
  }
}

/// Configures the Early Warning hardware diagnostics subsystem (`^JH`).
///
/// Useful for triggering alerts natively when printer head life is dying
/// or supplies are critically low.
class ZplEarlyWarning extends ZplCommand {
  /// The early warning category parameter (e.g., 'E' for Error, etc.).
  final String setting;

  /// The conditional sub-setting configuration.
  final String? value;

  const ZplEarlyWarning({required this.setting, this.value});

  @override
  int calculateWidth(ZplConfiguration config) => 0;

  @override
  String toZpl(ZplConfiguration config) {
    if (value != null && value!.isNotEmpty) {
      return '^JH$setting,$value\n';
    }
    return '^JH$setting\n';
  }
}
