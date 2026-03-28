import 'zpl_generator.dart';

/// A template engine that enables data binding onto pre-compiled raw ZPL strings.
///
/// This provides extreme performance benefits when generating thousands of identical
/// layout labels where only the textual data changes. Variables should be defined in
/// the `ZplCommand` instances exactly as `{{variable_name}}`.
class ZplTemplate {
  /// The base layout generator defining the label's static visual structure.
  final ZplGenerator generator;

  /// The cached Raw ZPL string (generated once upon initialization).
  String? _cachedZpl;

  /// Creates a [ZplTemplate] from an existing [ZplGenerator].
  ZplTemplate(this.generator);

  /// Initializes the template by executing the generator and caching the raw string.
  /// This must be called before [bindSync] to pre-parse layout logic or image resources.
  Future<void> init() async {
    _cachedZpl = await generator.build();
  }

  /// Injects data into the pre-built template safely using asynchronous fallbacks.
  ///
  /// Variables inside the [Map] correspond to `{{key}}` in the ZPL output.
  /// Automatically calls [init] if the template has not been cached yet.
  Future<String> bind(Map<String, dynamic> data) async {
    if (_cachedZpl == null) {
      await init();
    }

    return _replaceVariables(data);
  }

  /// Synchronous data binding designed perfectly for high-speed loops.
  ///
  /// Requires [init] to have been successfully completed beforehand. Throws
  /// a [StateError] if you forget to cache the template before binding synchronously.
  String bindSync(Map<String, dynamic> data) {
    if (_cachedZpl == null) {
      throw StateError(
        'ZplTemplate must be initialized with await init() before bindSync is called.',
      );
    }

    return _replaceVariables(data);
  }

  /// Internal function encapsulating standard string substitution mapping.
  String _replaceVariables(Map<String, dynamic> data) {
    String output = _cachedZpl!;

    // Instead of looping characters or complex AST evaluation,
    // ZPL is a flat string rendering format so direct replaceAll is heavily optimized natively.
    data.forEach((key, value) {
      output = output.replaceAll('{{$key}}', value.toString());
    });

    return output;
  }
}
