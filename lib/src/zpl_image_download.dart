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

  /// `none` → raw ASCII hex body; `acs` → ACS run-length encoded body.
  /// Both are legal inside `~DG` per the ZPL II Programming Guide.
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
    final rows = monochromeHexRows();
    final body = compression == ZplImageCompression.acs
        ? acsEncode(rows)
        : _rawHexBody(rows);
    return '~DG$graphicName,$totalBytes,$widthBytes,$body';
  }

  String _rawHexBody(List<String> rows) {
    final sb = StringBuffer();
    for (final row in rows) {
      sb.writeln(row);
    }
    return sb.toString();
  }
}
