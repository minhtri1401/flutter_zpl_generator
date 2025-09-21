import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:hex/hex.dart';
import 'zpl_font_asset.dart';

/// A service responsible for converting asset files into ZPL upload commands.
///
/// This service handles the conversion of local assets (like TTF fonts) into
/// ZPL commands that can be uploaded to the printer's memory. It maintains
/// separation of concerns by keeping asset conversion logic separate from
/// label generation and preview functionality.
///
/// Example usage:
/// ```dart
/// final assetService = ZplAssetService();
/// final fontAsset = ZplFontAsset(
///   assetPath: 'assets/fonts/Roboto-Regular.ttf',
///   identifier: 'A',
/// );
///
/// final uploadCommand = await assetService.getFontUploadCommand(fontAsset);
/// print(uploadCommand); // Outputs: ~DYE:AFONT.TTF,B,T,12345,,48656C6C6F...
/// ```
class ZplAssetService {
  /// Converts a [ZplFontAsset] into a ZPL `~DY` command for downloading
  /// the font to the printer's memory.
  ///
  /// The method loads the TTF font file from Flutter assets, converts it to
  /// hexadecimal format, and generates the appropriate `~DY` command that
  /// can be sent to a ZPL printer.
  ///
  /// Parameters:
  /// - [font]: The font asset to convert
  ///
  /// Returns:
  /// A Future containing the ZPL `~DY` command string that uploads the font
  /// to the printer's volatile memory (E: drive).
  ///
  /// Throws:
  /// - [FlutterError] if the asset path is invalid or the file cannot be loaded
  /// - [FormatException] if the font file is corrupted or invalid
  ///
  /// Example output:
  /// ```
  /// ~DYE:AFONT.TTF,B,T,45123,,504B030414000000080...
  /// ```
  ///
  /// Where:
  /// - `E:AFONT.TTF` is the path on the printer (E: = volatile memory)
  /// - `B` indicates binary data
  /// - `T` indicates TrueType font
  /// - `45123` is the byte count
  /// - The hex string contains the actual font data
  Future<String> getFontUploadCommand(ZplFontAsset font) async {
    try {
      // Load the font file from Flutter assets
      final byteData = await rootBundle.load(font.assetPath);
      final buffer = byteData.buffer;
      final fontBytes = buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      // Convert font bytes to uppercase hexadecimal string
      final hexString = HEX.encode(fontBytes).toUpperCase();
      final byteCount = fontBytes.length;

      // Generate printer path: E: is the printer's volatile memory drive
      final printerPath = 'E:${font.identifier}FONT.TTF';

      // Generate ZPL ~DY command
      // Format: ~DY<device>:<filename>,<format>,<extension>,<byte_count>,,<data>
      // - device: E (volatile memory)
      // - filename: {identifier}FONT.TTF
      // - format: B (binary)
      // - extension: T (TrueType)
      // - byte_count: number of bytes in the font file
      // - data: hexadecimal representation of the font
      return '~DY$printerPath,B,T,$byteCount,,$hexString';
    } catch (e) {
      throw Exception(
        'Failed to load font asset "${font.assetPath}": $e\n'
        'Make sure the font file exists in your assets and is properly '
        'declared in pubspec.yaml',
      );
    }
  }

  /// Converts an image asset into a ZPL graphic command.
  ///
  /// This method loads an image from Flutter assets, converts it to a format
  /// suitable for ZPL printers, and generates the appropriate upload command.
  ///
  /// Parameters:
  /// - [assetPath]: Path to the image asset
  /// - [identifier]: Single letter identifier (A-Z) for the graphic
  ///
  /// Returns:
  /// A Future containing the ZPL command to upload the image to the printer.
  ///
  /// Note: This is a placeholder for future image conversion functionality.
  /// The actual implementation would require image processing to convert
  /// the image to a ZPL-compatible format (monochrome bitmap).
  Future<String> getImageUploadCommand(
    String assetPath,
    String identifier,
  ) async {
    // TODO: Implement image to ZPL conversion
    // This would involve:
    // 1. Loading the image asset
    // 2. Converting to monochrome bitmap
    // 3. Generating ~DG command with hex data
    throw UnimplementedError(
      'Image upload functionality is not yet implemented. '
      'This feature will be added in a future version.',
    );
  }

  /// Validates that an asset path exists and can be loaded.
  ///
  /// This utility method can be used to check if an asset exists before
  /// attempting to convert it to ZPL commands.
  ///
  /// Parameters:
  /// - [assetPath]: The asset path to validate
  ///
  /// Returns:
  /// A Future<bool> indicating whether the asset exists and can be loaded.
  Future<bool> validateAssetPath(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (e) {
      return false;
    }
  }
}
