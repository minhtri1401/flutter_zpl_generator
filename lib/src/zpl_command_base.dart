import 'zpl_configuration.dart';

/// The base class for all ZPL commands.
abstract class ZplCommand {
  const ZplCommand();

  /// Converts the command to its ZPL representation.
  /// The [context] provides label configuration (dimensions, density, etc.).
  String toZpl(ZplConfiguration context);

  /// Calculates the approximate width of this command in dots.
  int calculateWidth(ZplConfiguration config);
}
