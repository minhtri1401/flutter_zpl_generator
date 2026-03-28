import 'zpl_command_base.dart';
import 'zpl_configuration.dart';
import 'enums.dart';

/// A class to handle barcode-related commands (^BC, ^B3, ^BQ, ^BX, ^BE, ^BU).
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

  /// The horizontal alignment of the barcode. If null, uses manual positioning.
  final ZplAlignment? alignment;

  /// Maximum width constraint (set by layout containers like ZplGridRow).
  final int? maxWidth;

  ZplBarcode({
    this.x = 0,
    this.y = 0,
    required this.data,
    this.type = ZplBarcodeType.code128,
    required this.height,
    this.orientation = ZplOrientation.normal,
    this.printInterpretationLine = true,
    this.printInterpretationLineAbove = false,
    this.moduleWidth,
    this.wideBarToNarrowBarRatio,
    this.alignment,
    this.maxWidth,
  });

  /// Calculate the approximate width of the barcode in dots.
  int get width {
    final baseModuleWidth = moduleWidth ?? 2;

    switch (type) {
      case ZplBarcodeType.code128:
        final baseWidth = ((data.length * 11) + 35) * baseModuleWidth;
        final quietZones = 20 * baseModuleWidth;
        return baseWidth + quietZones;

      case ZplBarcodeType.code39:
        final ratio = wideBarToNarrowBarRatio ?? 2.5;
        final baseWidth =
            ((data.length * (9 * ratio).round()) + 30) * baseModuleWidth;
        final quietZones = 20 * baseModuleWidth;
        return baseWidth + quietZones;

      case ZplBarcodeType.qrCode:
        if (data.length <= 25) return 84;
        if (data.length <= 47) return 100;
        if (data.length <= 77) return 116;
        if (data.length <= 114) return 132;
        return 148;

      case ZplBarcodeType.dataMatrix:
        // Data Matrix size estimate based on data length
        if (data.length <= 6) return 40;
        if (data.length <= 12) return 60;
        if (data.length <= 18) return 80;
        return 100;

      case ZplBarcodeType.ean13:
        // EAN-13: fixed 13 digits, standard width
        return (95 + 20) * baseModuleWidth; // 95 modules + quiet zones

      case ZplBarcodeType.upcA:
        // UPC-A: fixed 12 digits, standard width
        return (95 + 20) * baseModuleWidth; // 95 modules + quiet zones
    }
  }

  @override
  String toZpl(ZplConfiguration context) {
    final sb = StringBuffer();
    final alignedX = getAlignedX(context);
    sb.writeln('^FO$alignedX,$y');

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
        sb.writeln(
          '^BC$orientationCode,$height,$printLine,$printLineAbove,N,A',
        );
        sb.writeln('^FD$data^FS');
        break;

      case ZplBarcodeType.code39:
        final orientationCode = _getOrientationCode();
        final printLine = printInterpretationLine ? 'Y' : 'N';
        final printLineAbove = printInterpretationLineAbove ? 'Y' : 'N';
        sb.writeln('^B3$orientationCode,N,$height,$printLine,$printLineAbove');
        sb.writeln('^FD$data^FS');
        break;

      case ZplBarcodeType.qrCode:
        final orientationCode = _getOrientationCode();
        sb.writeln('^BQ$orientationCode,2,3');
        sb.writeln('^FD$data^FS');
        break;

      case ZplBarcodeType.dataMatrix:
        final orientationCode = _getOrientationCode();
        // ^BXo,h,q — orientation, height per module, quality level
        sb.writeln('^BX$orientationCode,$height,200');
        sb.writeln('^FD$data^FS');
        break;

      case ZplBarcodeType.ean13:
        final orientationCode = _getOrientationCode();
        final printLine = printInterpretationLine ? 'Y' : 'N';
        final printLineAbove = printInterpretationLineAbove ? 'Y' : 'N';
        // ^BEo,h,f,g
        sb.writeln('^BE$orientationCode,$height,$printLine,$printLineAbove');
        sb.writeln('^FD$data^FS');
        break;

      case ZplBarcodeType.upcA:
        final orientationCode = _getOrientationCode();
        final printLine = printInterpretationLine ? 'Y' : 'N';
        final printLineAbove = printInterpretationLineAbove ? 'Y' : 'N';
        // ^BUo,h,f,g,e
        sb.writeln('^BU$orientationCode,$height,$printLine,$printLineAbove,N');
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

  @override
  int calculateWidth(ZplConfiguration config) {
    return width;
  }

  /// Calculate the X position based on alignment and available width.
  int getAlignedX(ZplConfiguration context) {
    if (alignment == null) {
      return x;
    }

    final labelWidth = maxWidth ?? context.printWidth ?? 406;

    switch (alignment!) {
      case ZplAlignment.center:
        return x + ((labelWidth - width) ~/ 2).clamp(0, labelWidth - 1).toInt();
      case ZplAlignment.right:
        return x + (labelWidth - width).clamp(0, labelWidth - 1).toInt();
      case ZplAlignment.left:
        return x;
    }
  }
}
