import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// Configures advanced text properties like RTL (Right-to-Left) printing,
/// bidirectional text, and OpenType ligatures natively in ZPL.
///
/// Use this before printing Arabic, Hebrew, or complex scripts.
class ZplAdvancedTextProperties extends ZplCommand {
  /// Default character to print for unmatched glyphs.
  final int? defaultGlyph;

  /// Enable bidirectional text parsing capability.
  final bool? bidi;

  /// Enable complex character shaping (ligatures, connection forms).
  final bool? charShaping;

  /// Enable OpenType font support (true by default on modern Zebra firmware).
  final bool? openTypeSupport;

  const ZplAdvancedTextProperties({
    this.defaultGlyph,
    this.bidi,
    this.charShaping,
    this.openTypeSupport,
  });

  @override
  int calculateWidth(ZplConfiguration config) => 0;

  @override
  String toZpl(ZplConfiguration config) {
    final params = <String>[];
    if (defaultGlyph != null) {
      params.add(defaultGlyph.toString());
    } else {
      params.add('0'); // Firmware default is usually 0
    }

    params.add(bidi == true ? '1' : (bidi == false ? '0' : ''));
    params.add(charShaping == true ? '1' : (charShaping == false ? '0' : ''));
    params.add(
      openTypeSupport == true ? '1' : (openTypeSupport == false ? '0' : ''),
    );

    // Trim trailing empty commas if not provided, though ZPL ignores them safely
    while (params.isNotEmpty && params.last.isEmpty) {
      params.removeLast();
    }

    if (params.isEmpty) return '^PA\n';
    return '^PA${params.join(',')}\n';
  }
}

/// A block text field designed specifically for rendering paragraphs and
/// complex bidirectional text (like Arabic/Hebrew) using ^TB.
///
/// This behaves like a bounding box for text that forces wrapping and
/// supports correct shaping when combined with [ZplAdvancedTextProperties].
class ZplTextBlock extends ZplCommand {
  /// The X origin coordinate.
  final int x;

  /// The Y origin coordinate.
  final int y;

  /// The text content to print.
  final String text;

  /// Field orientation (N = Normal, R = Rotated 90 deg, I = Inverted 180 deg, B = Bottom-up 270 deg).
  final String orientation;

  /// The exact width of the text block bounding box in dots.
  final int maxWidth;

  /// The exact height of the text block bounding box in dots.
  final int maxHeight;

  const ZplTextBlock({
    this.x = 0,
    this.y = 0,
    required this.text,
    this.orientation = 'N',
    required this.maxWidth,
    required this.maxHeight,
  });

  @override
  int calculateWidth(ZplConfiguration config) => maxWidth;

  @override
  String toZpl(ZplConfiguration config) {
    return '^FO$x,$y^TB$orientation,$maxWidth,$maxHeight^FD$text^FS\n';
  }
}
