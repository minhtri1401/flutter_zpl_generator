import 'dart:typed_data';
import 'package:hex/hex.dart';
import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'zpl_asset_service.dart';

/// A ZPL control command that uploads a TrueType font to the printer's
/// volatile memory (E: drive) via `~DY`.
///
/// Emitted BEFORE `^XA` by [ZplGenerator.build] so the upload completes
/// before any format references the font. This ordering is required on
/// Link-OS mobile printers (ZQ620 etc.) and recommended on all Zebra
/// firmware per the ZPL II Programming Guide.
///
/// Example:
/// ```dart
/// final roboto = await ZplFontUpload.fromAsset(
///   'assets/fonts/Roboto-Regular.ttf',
///   'R',
/// );
/// final zpl = await ZplGenerator(
///   commands: [
///     roboto,
///     ZplText(text: 'Hi', customFont: roboto, fontHeight: 40),
///   ],
/// ).build();
/// ```
class ZplFontUpload extends ZplControlCommand {
  /// Single uppercase letter (A–Z) used to reference this font on the printer.
  final String identifier;

  /// Pre-loaded TrueType font bytes. Use [fromAsset] to load from Flutter assets.
  final Uint8List fontBytes;

  ZplFontUpload({required this.identifier, required this.fontBytes})
      : assert(
          RegExp(r'^[A-Z]$').hasMatch(identifier),
          'Font identifier must be a single uppercase letter (A-Z). '
          'Got: "$identifier"',
        );

  /// Loads the font bytes from a Flutter asset and returns a ready-to-use
  /// [ZplFontUpload]. Pass the result into [ZplGenerator.commands].
  static Future<ZplFontUpload> fromAsset(
    String assetPath,
    String identifier, {
    ZplAssetService? service,
  }) async {
    final svc = service ?? ZplAssetService();
    final bytes = await svc.loadFontBytes(assetPath);
    return ZplFontUpload(identifier: identifier, fontBytes: bytes);
  }

  /// The filename the font occupies on the printer. Format: `<id>FONT.TTF`.
  String get printerFileName => '${identifier}FONT.TTF';

  /// The full printer path including the volatile-memory drive prefix.
  /// Used by [ZplText.customFont] when selecting the font via `^A@`.
  String get printerPath => 'E:$printerFileName';

  @override
  String toZpl(ZplConfiguration context) {
    final hexString = HEX.encode(fontBytes).toUpperCase();
    return '~DY$printerPath,B,T,${fontBytes.length},,$hexString\n';
  }
}
