import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// A ZPL format command that recalls a previously-downloaded graphic at
/// position (x, y). Pair with a [ZplImageDownload] whose `graphicName`
/// matches this command's.
///
/// Emitted INSIDE the `^XA…^XZ` format block.
class ZplImageRecall extends ZplCommand {
  final int x;
  final int y;

  /// Must match a [ZplImageDownload.graphicName] registered before `^XA`.
  final String graphicName;

  /// Horizontal magnification factor applied by the printer (1–10).
  final int magnificationX;

  /// Vertical magnification factor applied by the printer (1–10).
  final int magnificationY;

  /// Optional explicit width so this command can participate in layout
  /// containers ([ZplColumn], [ZplGridRow]). Recall does not own the
  /// bitmap, so if layout math needs a dimension the user must provide it
  /// — typically by reading it off the paired [ZplImageDownload].
  final int? width;

  /// Optional explicit height counterpart to [width].
  final int? height;

  const ZplImageRecall({
    this.x = 0,
    this.y = 0,
    this.graphicName = 'IMG',
    this.magnificationX = 1,
    this.magnificationY = 1,
    this.width,
    this.height,
  });

  @override
  String toZpl(ZplConfiguration context) {
    final sb = StringBuffer();
    sb.writeln('^FO$x,$y');
    sb.writeln('^XG$graphicName,$magnificationX,$magnificationY^FS');
    return sb.toString();
  }

  @override
  int calculateWidth(ZplConfiguration config) => width ?? 0;
}
