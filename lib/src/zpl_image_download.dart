import 'dart:typed_data';
import 'image_payload_builder.dart';
import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'zpl_image_enums.dart';

/// A ZPL control command that downloads a monochrome graphic to the
/// printer's volatile memory via `~DG`. Pair with [ZplImageRecall] to
/// position and print it.
///
/// Emitted BEFORE `^XA` by [ZplGenerator.build] — required on Link-OS
/// mobile printers (ZQ620 etc.); recommended on all Zebra firmware per
/// the ZPL II Programming Guide.
class ZplImageDownload extends ZplControlCommand with ImagePayloadBuilder {
  @override
  final Uint8List image;

  /// Graphic name stored on the printer. [ZplImageRecall.graphicName] must match.
  final String graphicName;

  @override
  final int? targetWidth;
  @override
  final int? targetHeight;
  @override
  final bool maintainAspect;
  @override
  final ZplDitheringAlgorithm ditheringAlgorithm;

  /// Body encoding: `none` (raw hex), `acs` (run-length hex), `b64`
  /// (base64 + CRC) or `z64` (zlib + base64 + CRC, smallest). All four are
  /// legal inside `~DG`; `b64`/`z64` need B64/Z64-capable firmware.
  final ZplImageCompression compression;

  ZplImageDownload({
    required this.image,
    this.graphicName = 'IMG',
    this.targetWidth,
    this.targetHeight,
    this.maintainAspect = true,
    this.ditheringAlgorithm = ZplDitheringAlgorithm.floydSteinberg,
    this.compression = ZplImageCompression.none,
  });

  /// Post-resize width in dots (Bug 2 fix).
  int get width => renderedWidth;

  /// Post-resize height in dots (Bug 2 fix).
  int get height => renderedHeight;

  /// Offline-preview helper.
  ({int width, int height, List<bool> pixels})? getMonochromePixels() =>
      monochromePixels();

  @override
  String toZpl(ZplConfiguration context) {
    if (resizedImage() == null) return '';
    final body = graphicBody(compression);
    return '~DG$graphicName,$totalBytes,$widthBytes,$body';
  }
}
