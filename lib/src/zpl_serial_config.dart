/// Configuration for ZPL Serialization (^SN command).
///
/// Instructs the printer to automatically increment or decrement a value
/// on a multi-label print job (when used alongside ZplPrintQuantity).
class ZplSerialConfig {
  /// The increment or decrement step value (e.g., 1 or -1).
  /// ZPL will automatically find the right-most numeric substring
  /// in the text/barcode data and apply this step.
  final int increment;

  /// Whether to pad the incremented number with leading zeros
  /// to maintain the original string length.
  final bool leadingZeros;

  const ZplSerialConfig({this.increment = 1, this.leadingZeros = false});
}
