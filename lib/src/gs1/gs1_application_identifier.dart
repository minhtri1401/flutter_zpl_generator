/// The character kind an application identifier (AI) value may hold.
enum Gs1CharKind {
  /// Digits 0 to 9 only.
  digits,

  /// GS1 AI encodable character set 82 (printable ASCII subset).
  set82,
}

/// Why a value breaks the rule of its application identifier.
enum Gs1ValueError {
  /// The value is too short, too long, or empty.
  wrongLength,

  /// The AI takes digits only and the value holds something else.
  notDigits,

  /// The value holds a character outside GS1 character set 82.
  badCharacter,

  /// The GS1 mod-10 check digit does not match.
  badCheckDigit,

  /// The value is not a valid YYMMDD date.
  badDate,
}

/// Computes the GS1 mod-10 check digit for [body], the digits that come
/// before the check digit (13 digits for a GTIN-14).
///
/// Weights run 3, 1, 3, ... from the rightmost digit of [body].
int gs1CheckDigit(String body) {
  var sum = 0;
  var weight = 3;
  for (var i = body.length - 1; i >= 0; i--) {
    sum += (body.codeUnitAt(i) - 0x30) * weight;
    weight = weight == 3 ? 1 : 3;
  }
  return (10 - sum % 10) % 10;
}

/// Left-pads an 8, 12 or 13 digit GTIN (or any digit string up to 14) with
/// zeros to 14 digits. A longer value is returned unchanged.
String gs1PadGtinTo14(String gtin) => gtin.padLeft(14, '0');

/// Appends the GS1 check digit to a 13 digit GTIN body.
String gs1AppendCheckDigit(String body) => '$body${gs1CheckDigit(body)}';

final RegExp _placeholder = RegExp(r'^\{\{[^{}]*\}\}$');

/// True when [value] is one whole `{{placeholder}}`.
bool gs1IsPlaceholder(String value) => _placeholder.hasMatch(value);

/// One GS1 application identifier: its code, name and value rule.
class Gs1ApplicationIdentifier {
  const Gs1ApplicationIdentifier({
    required this.code,
    required this.name,
    required this.length,
    required this.variableLength,
    required this.charKind,
    this.isDate = false,
    this.hasCheckDigit = false,
  });

  /// The AI digits, for example `01`.
  final String code;

  /// English name, for example `GTIN`.
  final String name;

  /// The exact length when [variableLength] is false, otherwise the maximum.
  final int length;

  /// True when the value may be shorter than [length]. A variable-length
  /// value is followed by a group separator when another AI follows.
  final bool variableLength;

  /// Allowed characters.
  final Gs1CharKind charKind;

  /// True for YYMMDD dates (month 01 to 12, day 00 to the length of the month).
  final bool isDate;

  /// True when the last digit is a GS1 mod-10 check digit.
  final bool hasCheckDigit;

  /// The nine AIs the builder supports.
  static const List<Gs1ApplicationIdentifier> registry = [
    Gs1ApplicationIdentifier(
      code: '01',
      name: 'GTIN',
      length: 14,
      variableLength: false,
      charKind: Gs1CharKind.digits,
      hasCheckDigit: true,
    ),
    Gs1ApplicationIdentifier(
      code: '10',
      name: 'Batch or lot',
      length: 20,
      variableLength: true,
      charKind: Gs1CharKind.set82,
    ),
    Gs1ApplicationIdentifier(
      code: '11',
      name: 'Production date',
      length: 6,
      variableLength: false,
      charKind: Gs1CharKind.digits,
      isDate: true,
    ),
    Gs1ApplicationIdentifier(
      code: '13',
      name: 'Packaging date',
      length: 6,
      variableLength: false,
      charKind: Gs1CharKind.digits,
      isDate: true,
    ),
    Gs1ApplicationIdentifier(
      code: '15',
      name: 'Best before',
      length: 6,
      variableLength: false,
      charKind: Gs1CharKind.digits,
      isDate: true,
    ),
    Gs1ApplicationIdentifier(
      code: '17',
      name: 'Expiry',
      length: 6,
      variableLength: false,
      charKind: Gs1CharKind.digits,
      isDate: true,
    ),
    Gs1ApplicationIdentifier(
      code: '21',
      name: 'Serial',
      length: 20,
      variableLength: true,
      charKind: Gs1CharKind.set82,
    ),
    Gs1ApplicationIdentifier(
      code: '37',
      name: 'Count of items',
      length: 8,
      variableLength: true,
      charKind: Gs1CharKind.digits,
    ),
    Gs1ApplicationIdentifier(
      code: '3103',
      name: 'Net weight, kg, 3 decimals',
      length: 6,
      variableLength: false,
      charKind: Gs1CharKind.digits,
    ),
  ];

  /// The AI with [code], or null when it is not in the [registry].
  static Gs1ApplicationIdentifier? lookup(String code) {
    for (final ai in registry) {
      if (ai.code == code) return ai;
    }
    return null;
  }

  /// Checks [value] against this AI's rule. Returns the first broken rule,
  /// or null when the value is valid. A whole `{{placeholder}}` is valid.
  Gs1ValueError? validate(String value) {
    // `~` and `^` are ZPL control characters; a value must never carry one,
    // placeholder or not, or it could inject a FNC1 or group separator.
    if (value.contains('~') || value.contains('^')) {
      return Gs1ValueError.badCharacter;
    }
    if (gs1IsPlaceholder(value)) return null;
    if (value.isEmpty || value.length > length) {
      return Gs1ValueError.wrongLength;
    }
    if (!variableLength && value.length != length) {
      return Gs1ValueError.wrongLength;
    }
    if (charKind == Gs1CharKind.digits) {
      if (!_digitsOnly(value)) return Gs1ValueError.notDigits;
    } else if (!value.codeUnits.every(_inSet82)) {
      return Gs1ValueError.badCharacter;
    }
    if (isDate && !_validDate(value)) return Gs1ValueError.badDate;
    if (hasCheckDigit &&
        gs1CheckDigit(value.substring(0, value.length - 1)).toString() !=
            value[value.length - 1]) {
      return Gs1ValueError.badCheckDigit;
    }
    return null;
  }

  static bool _digitsOnly(String v) =>
      v.codeUnits.every((c) => c >= 0x30 && c <= 0x39);

  static bool _validDate(String v) {
    final year = 2000 + int.parse(v.substring(0, 2));
    final month = int.parse(v.substring(2, 4));
    final day = int.parse(v.substring(4, 6));
    if (month < 1 || month > 12) return false;
    final leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0);
    const days = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    final max = month == 2 && leap ? 29 : days[month - 1];
    return day <= max;
  }

  // GS1 set 82: ! " % & ' ( ) * + , - . / 0-9 : ; < = > ? A-Z _ a-z.
  static bool _inSet82(int c) =>
      c == 0x21 ||
      c == 0x22 ||
      (c >= 0x25 && c <= 0x3F) ||
      (c >= 0x41 && c <= 0x5A) ||
      c == 0x5F ||
      (c >= 0x61 && c <= 0x7A);
}
