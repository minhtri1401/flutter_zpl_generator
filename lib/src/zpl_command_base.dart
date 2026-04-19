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

/// Marker abstract subclass for ZPL *control* commands — those that start
/// with a tilde (`~DG`, `~DY`, `~JA`, …) and are processed immediately by
/// the printer's communication processor.
///
/// [ZplGenerator.build] emits instances of this class BEFORE the `^XA` that
/// opens the active format, matching Zebra's published recommendation. On
/// strict Link-OS firmware (e.g. ZQ620 V85.20) this placement is required —
/// embedding a tilde command inside an active format aborts or silently
/// discards the job.
///
/// Subclass this (not [ZplCommand]) when you author a new tilde-prefixed
/// command.
abstract class ZplControlCommand extends ZplCommand {
  const ZplControlCommand();

  /// Control commands have no layout footprint; layout containers skip them.
  @override
  int calculateWidth(ZplConfiguration config) => 0;
}
