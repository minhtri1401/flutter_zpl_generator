/// The base class for all ZPL commands.
abstract class ZplCommand {
  const ZplCommand();

  /// Converts the command to its ZPL representation.
  String toZpl();
}
