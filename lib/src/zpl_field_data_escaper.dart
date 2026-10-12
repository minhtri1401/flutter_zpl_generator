/// Escapes for text field data written after `^FD` or `^SN`.
///
/// The printer reads `^` as a format command and `~` as a control command
/// even inside field data, so text holding either is written behind `^FH`
/// (hex indicator `_`) with those characters, and the indicator itself, as
/// `_XX` hex escapes. Text without them is written as it is, so existing
/// labels keep their bytes.
///
/// `{{name}}` placeholders (the [ZplTemplate] grammar) are copied verbatim, so
/// a host that fills them into finished ZPL later can escape each value with
/// [hexEscape] in an `^FH` field and leave the placeholder names alone.
///
/// Rules for filling values into finished ZPL:
/// - Escape a fill-time value only when its field is preceded by `^FH`.
/// - A value holding `^` or `~` in a field without `^FH` stays unsafe, because
///   the host would have to insert `^FH` itself (zPrint refuses such values up
///   front).
/// - Substitute every `{{placeholder}}` (with `''` when empty) before
///   printing: a literal `{{lot_no}}` under `^FH` prints its `_no` garbled.
abstract final class ZplFieldDataEscaper {
  static const int _underscore = 0x5F;
  static const int _caret = 0x5E;
  static const int _tilde = 0x7E;

  static final RegExp _placeholder = RegExp(r'\{\{\w+\}\}');

  /// Whether [data] holds `^` or `~` and must go out behind `^FH`.
  static bool needsHex(String data) {
    for (final unit in data.codeUnits) {
      if (unit == _caret || unit == _tilde) return true;
    }
    return false;
  }

  /// [data] with `_`, `^` and `~` written as `_5F`, `_5E` and `_7E`.
  ///
  /// Spans matching `{{name}}` are left as they are.
  static String hexEscape(String data) {
    final out = StringBuffer();
    var last = 0;
    for (final match in _placeholder.allMatches(data)) {
      _writeEscaped(out, data.substring(last, match.start));
      out.write(match.group(0));
      last = match.end;
    }
    _writeEscaped(out, data.substring(last));
    return out.toString();
  }

  static void _writeEscaped(StringBuffer out, String part) {
    for (final rune in part.runes) {
      if (rune == _underscore || rune == _caret || rune == _tilde) {
        out.write('_${rune.toRadixString(16).toUpperCase()}');
      } else {
        out.writeCharCode(rune);
      }
    }
  }
}
