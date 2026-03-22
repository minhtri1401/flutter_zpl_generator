import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'zpl_font_asset.dart';
import 'zpl_asset_service.dart';

/// The main class that aggregates a list of ZPL commands and generates the
/// final, printable ZPL script string.
///
/// Configuration is provided directly via [config] and passed as context to
/// all commands, eliminating the need for a separate configuration command
/// in the command list.
class ZplGenerator {
  /// Global label configuration (dimensions, density, darkness, etc.).
  final ZplConfiguration config;

  /// A list of [ZplCommand] objects that make up the label.
  final List<ZplCommand> commands;

  /// A list of custom fonts to upload to the printer before the label commands.
  final List<ZplFontAsset> fonts;

  /// The service used to convert font assets to ZPL upload commands.
  /// If null, a default instance will be created when needed.
  final ZplAssetService? assetService;

  ZplGenerator({
    this.config = const ZplConfiguration(),
    required this.commands,
    this.fonts = const [],
    this.assetService,
  });

  /// Builds the complete ZPL script.
  ///
  /// Wraps all commands with `^XA` / `^XZ`, uploads any custom fonts first,
  /// then emits the configuration and all label commands.
  Future<String> build() async {
    final sb = StringBuffer();
    sb.writeln('^XA');

    if (fonts.isNotEmpty) {
      final service = assetService ?? ZplAssetService();
      for (final font in fonts) {
        final uploadCommand = await service.getFontUploadCommand(font);
        sb.writeln(uploadCommand);
      }
    }

    sb.write(config.toZpl());

    for (final command in commands) {
      sb.write(command.toZpl(config));
    }

    sb.writeln('^XZ');
    return sb.toString();
  }
}
