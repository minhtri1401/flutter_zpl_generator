import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'zpl_column.dart';
import 'zpl_row.dart';
import 'zpl_grid_row.dart';
import 'zpl_table.dart';
import 'zpl_text.dart';
import 'zpl_barcode.dart';
import 'zpl_separator.dart';
import 'zpl_font_asset.dart';
import 'zpl_asset_service.dart';

/// The main class that aggregates a list of ZPL commands and generates the
/// final, printable ZPL script string.
///
/// This generator now supports custom fonts through the [ZplAssetService].
/// Fonts will be automatically uploaded to the printer before the label commands.
class ZplGenerator {
  /// A list of [ZplCommand] objects that make up the label. The commands will
  /// be processed in the order they appear in the list.
  final List<ZplCommand> commands;

  /// A list of custom fonts to upload to the printer.
  /// These fonts must be uploaded before any text commands that use them.
  final List<ZplFontAsset> fonts;

  /// The service used to convert font assets to ZPL upload commands.
  /// If null, a default instance will be created.
  final ZplAssetService? assetService;

  ZplGenerator(this.commands, {this.fonts = const [], this.assetService});

  /// Builds the complete ZPL script.
  ///
  /// This method wraps the combined ZPL from all commands with the
  /// standard ZPL start (`^XA`) and end (`^XZ`) commands, making it ready
  /// to be sent to a Zebra printer.
  ///
  /// If custom fonts are specified, they will be uploaded first using
  /// the [ZplAssetService].
  Future<String> build() async {
    final sb = StringBuffer();
    sb.writeln('^XA');

    // Upload custom fonts first (if any)
    if (fonts.isNotEmpty) {
      final service = assetService ?? ZplAssetService();
      for (final font in fonts) {
        final uploadCommand = await service.getFontUploadCommand(font);
        sb.writeln(uploadCommand);
      }
    }

    // First pass: find configuration and apply it to layout components
    ZplConfiguration? config;
    for (final command in commands) {
      if (command is ZplConfiguration) {
        config = command;
        break;
      }
    }

    // Second pass: apply configuration context to layout components
    if (config != null) {
      _applyConfigurationToLayouts(commands, config);
    }

    // Third pass: generate ZPL
    for (final command in commands) {
      sb.write(command.toZpl());
    }

    sb.writeln('^XZ');
    return sb.toString();
  }

  /// Recursively apply configuration context to layout components
  void _applyConfigurationToLayouts(
    List<ZplCommand> commands,
    ZplConfiguration config,
  ) {
    for (final command in commands) {
      if (command is ZplColumn) {
        command.setConfiguration(config);
        // Also apply to nested children recursively
        _applyConfigurationToLayouts(command.children, config);
      } else if (command is ZplRow) {
        command.setConfiguration(config);
        // Also apply to nested children recursively
        _applyConfigurationToLayouts(command.children, config);
      } else if (command is ZplGridRow) {
        command.setConfiguration(config);
        // Note: ZplGridRow handles its own child configuration internally
      } else if (command is ZplTable) {
        command.setConfiguration(config);
        // Note: ZplTable handles its own child configuration internally
      } else if (command is ZplText) {
        command.setConfiguration(config);
      } else if (command is ZplBarcode) {
        command.setConfiguration(config);
      } else if (command is ZplSeparator) {
        command.setConfiguration(config);
      }
    }
  }
}
