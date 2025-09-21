/// A data class representing a TrueType Font asset to be used on a ZPL label.
///
/// This class serves as a simple container for font asset information.
/// The actual conversion to ZPL upload commands is handled by [ZplAssetService].
///
/// Example usage:
/// ```dart
/// final robotoFont = ZplFontAsset(
///   assetPath: 'assets/fonts/Roboto-Regular.ttf',
///   identifier: 'A',
/// );
///
/// // Use with ZplAssetService to generate upload command
/// final assetService = ZplAssetService();
/// final uploadCommand = await assetService.getFontUploadCommand(robotoFont);
///
/// // Use in ZplText to apply the font
/// final text = ZplText(
///   text: 'Custom font text',
///   customFont: robotoFont,
/// );
/// ```
class ZplFontAsset {
  /// The path to the font asset in your Flutter project.
  ///
  /// This should be a valid asset path that's declared in your `pubspec.yaml`
  /// file under the `assets` section.
  ///
  /// Example: `'assets/fonts/Roboto-Regular.ttf'`
  final String assetPath;

  /// The single character identifier that will be used to reference this font
  /// on the printer after it's uploaded.
  ///
  /// This must be a single uppercase letter from A-Z. Each font in your
  /// label must have a unique identifier.
  ///
  /// Example: `'A'` for the first custom font, `'B'` for the second, etc.
  final String identifier;

  /// An optional human-readable name for the font.
  ///
  /// This is used for documentation and debugging purposes only.
  /// It does not affect the ZPL generation.
  final String? displayName;

  /// Creates a new font asset definition.
  ///
  /// Parameters:
  /// - [assetPath]: Path to the TTF font file in your Flutter assets
  /// - [identifier]: Single letter (A-Z) to identify this font on the printer
  /// - [displayName]: Optional human-readable name for documentation
  ///
  /// Throws:
  /// - [AssertionError] if the identifier is not a single uppercase letter
  ///
  /// Example:
  /// ```dart
  /// final font = ZplFontAsset(
  ///   assetPath: 'assets/fonts/Roboto-Bold.ttf',
  ///   identifier: 'B',
  ///   displayName: 'Roboto Bold',
  /// );
  /// ```
  ZplFontAsset({
    required this.assetPath,
    required this.identifier,
    this.displayName,
  }) : assert(
         RegExp(r'^[A-Z]$').hasMatch(identifier),
         'Font identifier must be a single uppercase letter (A-Z). '
         'Got: "$identifier"',
       ),
       assert(assetPath.isNotEmpty, 'Asset path cannot be empty');

  /// Returns the filename that will be used when the font is stored on the printer.
  ///
  /// Format: `{identifier}FONT.TTF`
  /// Example: For identifier 'A', returns 'AFONT.TTF'
  String get printerFileName => '${identifier}FONT.TTF';

  /// Returns the full path where the font will be stored on the printer.
  ///
  /// Uses the volatile memory drive (E:) by default.
  /// Example: For identifier 'A', returns 'E:AFONT.TTF'
  String get printerPath => 'E:$printerFileName';

  /// Returns a string representation of this font asset.
  ///
  /// Useful for debugging and logging.
  @override
  String toString() {
    final name = displayName != null ? ' ($displayName)' : '';
    return 'ZplFontAsset{identifier: $identifier, path: $assetPath$name}';
  }

  /// Compares two font assets for equality.
  ///
  /// Two font assets are considered equal if they have the same
  /// identifier and asset path.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZplFontAsset &&
        other.identifier == identifier &&
        other.assetPath == assetPath;
  }

  /// Returns the hash code for this font asset.
  @override
  int get hashCode => Object.hash(identifier, assetPath);
}
