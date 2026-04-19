import 'package:flutter/services.dart';

/// A thin helper for loading binary assets (currently: TrueType fonts) from
/// Flutter's asset bundle.
///
/// In v2.0 the `~DY` command emission moved to [ZplFontUpload.toZpl]; this
/// service now only provides the low-level asset read, which
/// [ZplFontUpload.fromAsset] consumes.
class ZplAssetService {
  /// Loads the raw bytes of a font asset.
  ///
  /// Throws [Exception] if the asset cannot be loaded (wrong path, not
  /// declared in `pubspec.yaml`, etc.).
  Future<Uint8List> loadFontBytes(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      return byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
    } catch (e) {
      throw Exception(
        'Failed to load font asset "$assetPath": $e\n'
        'Make sure the font file exists in your assets and is properly '
        'declared in pubspec.yaml',
      );
    }
  }

  /// Validates that an asset path exists and can be loaded.
  Future<bool> validateAssetPath(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
