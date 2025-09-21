import 'dart:typed_data';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'zpl_command_base.dart';
import 'enums.dart';

/// A class to handle downloading a font asset (e.g., a .TTF file) to the printer.
/// It generates the ~DU (Download Unbounded TrueType Font) command to store the font
/// and the ^CW (Font Identifier) command to assign it a character alias.
class ZplFontAsset extends ZplCommand {
  /// The single character alias (A-Z, 0-9) to assign to the font. This alias
  /// is used in other commands like [ZplText] to select the font.
  final String alias;

  /// The name of the font file to be stored on the printer.
  /// It is strongly recommended that this name ends with .TTF.
  final String fileName;

  /// The raw byte data of the font file.
  final Uint8List fontData;

  /// The storage location for the font (default: flash memory for persistence).
  final ZplStorage storage;

  const ZplFontAsset({
    required this.alias,
    required this.fileName,
    required this.fontData,
    this.storage = ZplStorage.flash,
  });

  @override
  String toZpl() {
    // Basic validation
    if (alias.length != 1 ||
        !RegExp(r'[A-Z0-9]').hasMatch(alias.toUpperCase())) {
      throw ArgumentError(
        'Font alias must be a single alphanumeric character (A-Z, 0-9).',
      );
    }

    final sb = StringBuffer();

    // 1. Download the font data using ~DU command
    // Format: ~DUd:o.x,s,data
    // d = destination drive (E: non-volatile, R: volatile memory)
    // o.x = object name (filename)
    // s = size in bytes
    // data = hexadecimal representation of the font file
    final size = fontData.lengthInBytes;
    final hexData = fontData
        .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join();

    sb.writeln('~DU${storage.path}$fileName,$size,');
    sb.writeln(hexData);

    // 2. Assign an alias to the downloaded font using ^CW command
    // Format: ^CWa,d:o.x
    // a = alias
    // d:o.x = full path to the font on the printer
    sb.writeln('^CW$alias,${storage.path}$fileName');

    return sb.toString();
  }

  @override
  int calculateWidth(ZplConfiguration? config) {
    return 0; // Font asset commands don't occupy visual space
  }
}
