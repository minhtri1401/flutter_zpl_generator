import 'gs1_application_identifier.dart';

/// One application identifier with its value.
class Gs1Element {
  const Gs1Element(this.ai, this.value);

  final Gs1ApplicationIdentifier ai;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is Gs1Element && other.ai.code == ai.code && other.value == value;

  @override
  int get hashCode => Object.hash(ai.code, value);

  @override
  String toString() => '(${ai.code})$value';
}

/// Parsing, formatting and FNC1 conversion for GS1 element strings.
///
/// The parenthesised form is `(01)09501101530003(17)261231(10)A1`.
/// The FNC1 form is `<esc>1` followed by AI codes and values without
/// parentheses, with `<esc>d029` after each variable-length value that another
/// AI follows.
class Gs1ElementString {
  const Gs1ElementString._();

  /// Parses the parenthesised form into ordered elements. Values are not
  /// validated. Throws [FormatException] on an unknown AI, malformed
  /// brackets, an empty value, or empty input.
  static List<Gs1Element> parse(String text) {
    if (text.isEmpty) throw const FormatException('Empty element string');
    final out = <Gs1Element>[];
    var i = 0;
    while (i < text.length) {
      if (text[i] != '(') {
        throw FormatException('Expected "(" at $i', text, i);
      }
      final close = text.indexOf(')', i);
      if (close < 0) throw FormatException('Missing ")"', text, i);
      final code = text.substring(i + 1, close);
      if (code.contains('(')) {
        throw FormatException('Nested "("', text, i);
      }
      final ai = Gs1ApplicationIdentifier.lookup(code);
      if (ai == null) throw FormatException('Unknown AI "$code"', text, i);
      var end = text.indexOf('(', close + 1);
      if (end < 0) end = text.length;
      final value = text.substring(close + 1, end);
      if (value.isEmpty) throw FormatException('Empty value for $code', text);
      if (value.contains(')')) {
        throw FormatException('Stray ")" in value', text, close);
      }
      if (out.any((e) => e.ai.code == ai.code)) {
        throw FormatException('Repeated AI $code', text, i);
      }
      out.add(Gs1Element(ai, value));
      i = end;
    }
    return out;
  }

  /// Like [parse] but returns null instead of throwing.
  static List<Gs1Element>? tryParse(String text) {
    try {
      return parse(text);
    } on FormatException {
      return null;
    }
  }

  /// Formats [elements] as `(01)...(17)...`.
  static String format(List<Gs1Element> elements) =>
      elements.map((e) => '(${e.ai.code})${e.value}').join();

  /// Converts [elements] to the FNC1 form for [escape] (`~` by default).
  /// Throws [FormatException] when a value contains [escape], which would
  /// inject a FNC1 or separator.
  static String toFnc1(List<Gs1Element> elements, {String escape = '~'}) {
    final b = StringBuffer('${escape}1');
    for (var i = 0; i < elements.length; i++) {
      final e = elements[i];
      if (e.value.contains(escape)) {
        throw FormatException(
          'Value of ${e.ai.code} contains the escape character',
          e.value,
        );
      }
      b
        ..write(e.ai.code)
        ..write(e.value);
      if (e.ai.variableLength && i < elements.length - 1) {
        b.write('${escape}d029');
      }
    }
    return b.toString();
  }

  /// Converts [elements] straight from parenthesised text to the FNC1 form.
  /// Throws [FormatException] like [parse].
  static String parenthesisedToFnc1(String text, {String escape = '~'}) =>
      toFnc1(parse(text), escape: escape);

  /// Converts concrete FNC1 data back to elements, using the AI table to split
  /// fixed-length values. A whole `{{placeholder}}` is kept as one value.
  /// Throws [FormatException] on a missing prefix, unknown AI, or bad length.
  static List<Gs1Element> fromFnc1(String data, {String escape = '~'}) {
    final prefix = '${escape}1';
    final sep = '${escape}d029';
    if (!data.startsWith(prefix)) {
      throw const FormatException('Missing FNC1 prefix');
    }
    final out = <Gs1Element>[];
    var i = prefix.length;
    if (i >= data.length) throw const FormatException('No data after FNC1');
    while (i < data.length) {
      final ai = _aiAt(data, i);
      if (ai == null) throw FormatException('Unknown AI', data, i);
      i += ai.code.length;
      int end;
      if (data.startsWith('{{', i)) {
        final close = data.indexOf('}}', i);
        if (close < 0) throw FormatException('Open placeholder', data, i);
        end = close + 2;
      } else if (ai.variableLength) {
        final s = data.indexOf(sep, i);
        end = s < 0 ? data.length : s;
      } else {
        end = i + ai.length;
        if (end > data.length) {
          throw FormatException('Value too short for ${ai.code}', data, i);
        }
      }
      if (end == i) throw FormatException('Empty value', data, i);
      if (out.any((e) => e.ai.code == ai.code)) {
        throw FormatException('Repeated AI ${ai.code}', data, i);
      }
      out.add(Gs1Element(ai, data.substring(i, end)));
      i = end;
      if (data.startsWith(sep, i)) {
        i += sep.length;
        if (i >= data.length) {
          throw const FormatException('Trailing separator');
        }
      }
    }
    return out;
  }

  /// Like [fromFnc1] but returns null instead of throwing.
  static List<Gs1Element>? tryFromFnc1(String data, {String escape = '~'}) {
    try {
      return fromFnc1(data, escape: escape);
    } on FormatException {
      return null;
    }
  }

  static Gs1ApplicationIdentifier? _aiAt(String data, int i) {
    for (final len in const [4, 2]) {
      if (i + len > data.length) continue;
      final ai = Gs1ApplicationIdentifier.lookup(data.substring(i, i + len));
      if (ai != null) return ai;
    }
    return null;
  }
}
