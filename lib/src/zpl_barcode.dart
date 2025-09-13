import 'zpl_command_base.dart';
import 'enums.dart';

/// A class to handle barcode-related commands, starting with Code 128 (^BC).
class ZplBarcode extends ZplCommand {
  /// The x-axis position of the barcode.
  final int x;

  /// The y-axis position of the barcode.
  final int y;

  /// The data to be encoded in the barcode.
  final String data;

  /// The type of barcode to generate. Defaults to Code 128.
  final ZplBarcodeType type;

  /// The height of the barcode in dots.
  final int height;

  /// The orientation of the barcode. Defaults to normal.
  final ZplOrientation orientation;

  /// Whether to print the human-readable interpretation line below the barcode.
  final bool printInterpretationLine;

  /// Whether to print the interpretation line above the barcode instead of below.
  final bool printInterpretationLineAbove;

  /// The module width (width of the narrowest bar) in dots. A value between 1 and 10.
  final int? moduleWidth;

  /// The wide bar to narrow bar width ratio. A value between 2.0 and 3.0.
  final double? wideBarToNarrowBarRatio;

  const ZplBarcode({
    required this.x,
    required this.y,
    required this.data,
    this.type = ZplBarcodeType.code128,
    required this.height,
    this.orientation = ZplOrientation.normal,
    this.printInterpretationLine = true,
    this.printInterpretationLineAbove = false,
    this.moduleWidth,
    this.wideBarToNarrowBarRatio,
  });

  @override
  String toZpl() {
    final sb = StringBuffer();
    sb.writeln('^FO$x,$y');

    if (moduleWidth != null || wideBarToNarrowBarRatio != null) {
      final w = moduleWidth ?? '';
      final r = wideBarToNarrowBarRatio ?? '';
      sb.writeln('^BY$w,$r');
    }

    switch (type) {
      case ZplBarcodeType.code128:
        final orientationCode = _getOrientationCode();
        final printLine = printInterpretationLine ? 'Y' : 'N';
        final printLineAbove = printInterpretationLineAbove ? 'Y' : 'N';

        // ^BCo,h,f,g,e,m
        // Using default for UCC check digit (e='N') and Automatic mode (m='A')
        sb.writeln(
          '^BC$orientationCode,$height,$printLine,$printLineAbove,N,A',
        );
        sb.writeln('^FD$data^FS');
        break;
      case ZplBarcodeType.code39:
        final orientationCode = _getOrientationCode();
        final printLine = printInterpretationLine ? 'Y' : 'N';
        final printLineAbove = printInterpretationLineAbove ? 'Y' : 'N';

        // ^B3o,e,h,f,g
        sb.writeln('^B3$orientationCode,N,$height,$printLine,$printLineAbove');
        sb.writeln('^FD$data^FS');
        break;
      case ZplBarcodeType.qrCode:
        final orientationCode = _getOrientationCode();

        // ^BQo,model,magnification
        sb.writeln('^BQ$orientationCode,2,3');
        sb.writeln('^FD$data^FS');
        break;
    }
    return sb.toString();
  }

  String _getOrientationCode() {
    switch (orientation) {
      case ZplOrientation.normal:
        return 'N';
      case ZplOrientation.rotated90:
        return 'R';
      case ZplOrientation.inverted180:
        return 'I';
      case ZplOrientation.readFromBottomUp270:
        return 'B';
    }
  }
}
