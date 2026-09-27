import 'dart:typed_data';
import 'image_payload_builder.dart';
import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'zpl_image_enums.dart';

/// A ZPL format command that emits a one-shot compressed graphic inline via
/// `^GFA`. No `~DG` separate-download step — the bitmap travels inside the
/// active format. Best when you print the image once and never reuse.
///
/// [compression] defaults to ACS (the 2.0 behaviour). Use
/// [ZplImageCompression.z64] for the smallest payload on firmware that
/// supports it.
///
/// Use [ZplImageDownload] + [ZplImageRecall] instead on Link-OS mobile
/// firmware (ZQ620 etc.) — inline `^GFA` works on desktop firmware but has
/// been observed silently failing on ZQ620 at high dot coverage; see
/// `doc/mobile-printer-guide.md`.
class ZplImageInline extends ZplCommand with ImagePayloadBuilder {
  final int x;
  final int y;

  @override
  final Uint8List image;
  @override
  final int? targetWidth;
  @override
  final int? targetHeight;
  @override
  final bool maintainAspect;
  @override
  final ZplDitheringAlgorithm ditheringAlgorithm;

  /// Body encoding; see [ZplImageCompression]. Defaults to `acs`.
  final ZplImageCompression compression;

  ZplImageInline({
    this.x = 0,
    this.y = 0,
    required this.image,
    this.targetWidth,
    this.targetHeight,
    this.maintainAspect = true,
    this.ditheringAlgorithm = ZplDitheringAlgorithm.floydSteinberg,
    this.compression = ZplImageCompression.acs,
  });

  /// Post-resize width in dots (Bug 2 fix).
  int get width => renderedWidth;

  /// Post-resize height in dots (Bug 2 fix).
  int get height => renderedHeight;

  ({int width, int height, List<bool> pixels})? getMonochromePixels() =>
      monochromePixels();

  @override
  String toZpl(ZplConfiguration context) {
    if (resizedImage() == null) return '';
    final sb = StringBuffer();
    sb.writeln('^FO$x,$y');
    sb.write('^GFA,$totalBytes,$totalBytes,$widthBytes,');
    sb.write(graphicBody(compression));
    sb.writeln('^FS');
    return sb.toString();
  }

  @override
  int calculateWidth(ZplConfiguration config) => width;
}
