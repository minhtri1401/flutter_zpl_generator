import 'zpl_configuration.dart';

/// The base class for all ZPL commands.
abstract class ZplCommand {
  const ZplCommand();

  /// Converts the command to its ZPL representation.
  String toZpl();

  /// Calculates the approximate width of this command in dots.
  ///
  /// This method should return the width that this command will occupy
  /// when rendered on the label. The [config] parameter provides context
  /// about the label dimensions and printer settings.
  int calculateWidth(ZplConfiguration? config);
}
