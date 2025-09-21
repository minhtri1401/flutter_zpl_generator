import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

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

  /// The horizontal alignment of the barcode. If null, uses manual positioning.
  final ZplAlignment? alignment;

  /// Optional configuration context for alignment features
  ZplConfiguration? _configuration;

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
  });

  /// Set configuration context for alignment features
  void setConfiguration(ZplConfiguration config) {
    _configuration = config;
  }

  /// Calculate the approximate width of the barcode in dots.
  /// This is an estimation based on barcode type and data length.
  int get width {
    final baseModuleWidth = moduleWidth ?? 2; // Default module width

    switch (type) {
      case ZplBarcodeType.code128:
        // Code 128: Each character is 11 modules wide
        // Plus start code (11), stop code (13), and check digit (11)
        // Base calculation: (data_length * 11) + 35 modules
        // Add quiet zones (10 modules each side) and interpretation line considerations
        final baseWidth = ((data.length * 11) + 35) * baseModuleWidth;
        final quietZones = 20 * baseModuleWidth; // 10 modules each side
        return baseWidth + quietZones;

      case ZplBarcodeType.code39:
        // Code 39: Each character is 5 bars + 4 spaces = 9 modules
        // Wide bars/spaces are typically 3x narrow (using wideBarToNarrowBarRatio)
        // Plus start/stop characters (* = 15 modules each)
        final ratio = wideBarToNarrowBarRatio ?? 2.5;
        final baseWidth =
            ((data.length * (9 * ratio).round()) + 30) * baseModuleWidth;
        final quietZones = 20 * baseModuleWidth; // Quiet zones
        return baseWidth + quietZones;

      case ZplBarcodeType.qrCode:
        // QR Code size depends on data length and error correction level
        // These already include quiet zones in the estimation
        if (data.length <= 25) {
          return 84; // Version 1: 21x21 modules * 4 = 84 dots
        }
        if (data.length <= 47) {
          return 100; // Version 2: 25x25 modules * 4 = 100 dots
        }
        if (data.length <= 77) {
          return 116; // Version 3: 29x29 modules * 4 = 116 dots
        }
        if (data.length <= 114) {
          return 132; // Version 4: 33x33 modules * 4 = 132 dots
        }
        return 148; // Version 5+: 37x37 modules * 4 = 148 dots (default)
    }
  }

  @override
  String toZpl() {
    final sb = StringBuffer();

    // Calculate aligned X position if alignment is specified
    // Note: Unlike text, barcodes cannot use ^FB, so we use manual positioning
    // to achieve the same alignment behavior as ^FB does for text
    final alignedX = _calculateAlignedX();
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

  @override
  int calculateWidth(ZplConfiguration? config) {
    return width; // Use the calculated width property
  }

  /// Calculate the X position based on alignment and available width
  /// This mimics the ^FB behavior for barcodes using manual positioning
  int _calculateAlignedX() {
    // If no alignment or configuration, use specified x position
    if (alignment == null || _configuration == null) {
      return x;
    }

    // Use x=0 when alignment is specified (like ^FB does for text)
    // This allows the alignment to work from the full label width
    if (x == 0) {
      final labelWidth = _configuration!.printWidth ?? 406;
      final barcodeWidth = width;

      switch (alignment!) {
        case ZplAlignment.center:
          return ((labelWidth - barcodeWidth) ~/ 2).clamp(0, labelWidth - 1);
        case ZplAlignment.right:
          return (labelWidth - barcodeWidth).clamp(0, labelWidth - 1);
        case ZplAlignment.left:
          return 0;
      }
    }

    // If x is explicitly set (non-zero), use manual positioning like text does
    return x;
  }
}
