import 'dart:ui';

import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'label_element.dart';

/// Editable barcode mapping to [ZplBarcode].
class BarcodeElement extends LabelElement {
  final String data;
  final ZplBarcodeType type;
  final int height;
  final ZplOrientation orientation;
  final bool printInterpretationLine;
  final bool printInterpretationLineAbove;
  final int moduleWidth;
  final int magnification;
  final ZplQrErrorCorrection qrErrorCorrection;

  /// Approximate height of the human-readable line under 1D barcodes, in dots.
  static const int interpretationLineHeight = 20;

  const BarcodeElement({
    required super.id,
    super.x = 0,
    super.y = 0,
    required this.data,
    this.type = ZplBarcodeType.code128,
    this.height = 80,
    this.orientation = ZplOrientation.normal,
    this.printInterpretationLine = true,
    this.printInterpretationLineAbove = false,
    this.moduleWidth = 2,
    this.magnification = 3,
    this.qrErrorCorrection = ZplQrErrorCorrection.medium,
  });

  @override
  String get typeName => 'barcode';

  bool get isTwoDimensional =>
      type == ZplBarcodeType.qrCode ||
      type == ZplBarcodeType.dataMatrix ||
      type == ZplBarcodeType.aztec;

  /// PDF417 (`^B7`) never prints a human-readable line.
  bool get hasInterpretationLine =>
      printInterpretationLine &&
      !isTwoDimensional &&
      type != ZplBarcodeType.pdf417;

  BarcodeElement copyWith({
    int? x,
    int? y,
    String? data,
    ZplBarcodeType? type,
    int? height,
    ZplOrientation? orientation,
    bool? printInterpretationLine,
    bool? printInterpretationLineAbove,
    int? moduleWidth,
    int? magnification,
    ZplQrErrorCorrection? qrErrorCorrection,
  }) {
    return BarcodeElement(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      data: data ?? this.data,
      type: type ?? this.type,
      height: height ?? this.height,
      orientation: orientation ?? this.orientation,
      printInterpretationLine:
          printInterpretationLine ?? this.printInterpretationLine,
      printInterpretationLineAbove:
          printInterpretationLineAbove ?? this.printInterpretationLineAbove,
      moduleWidth: moduleWidth ?? this.moduleWidth,
      magnification: magnification ?? this.magnification,
      qrErrorCorrection: qrErrorCorrection ?? this.qrErrorCorrection,
    );
  }

  @override
  ZplBarcode toCommand() => ZplBarcode(
        x: x,
        y: y,
        data: data,
        type: type,
        height: height.clamp(1, 32000),
        orientation: orientation,
        printInterpretationLine: printInterpretationLine,
        printInterpretationLineAbove: printInterpretationLineAbove,
        moduleWidth: moduleWidth.clamp(1, 10),
        magnification: magnification.clamp(1, 10),
        qrErrorCorrection: qrErrorCorrection,
      );

  @override
  Rect bounds(ZplConfiguration config) {
    final width = toCommand().width.toDouble();
    double h;
    if (isTwoDimensional) {
      h = width; // square symbols; package estimator already applies magnification
    } else {
      h = height.toDouble();
      if (hasInterpretationLine) h += interpretationLineHeight;
    }
    final size = orientedSize(orientation, width, h);
    return Rect.fromLTWH(x.toDouble(), y.toDouble(), size.width, size.height);
  }

  @override
  BarcodeElement moveTo(int x, int y) => copyWith(x: x, y: y);

  /// 1D: height follows the handle, module width scales with width.
  /// 2D: magnification scales with the larger side.
  @override
  BarcodeElement resizeTo(int width, int height) {
    // Handles work in oriented space; bar metrics are un-oriented.
    final unoriented = orientedSize(orientation, width.toDouble(), height.toDouble());
    width = unoriented.width.round();
    height = unoriented.height.round();
    final b = bounds(const ZplConfiguration());
    final current = orientedSize(orientation, b.width, b.height);
    if (isTwoDimensional) {
      final scale = current.width > 0 ? width / current.width : 1.0;
      return copyWith(
        magnification: (magnification * scale).round().clamp(1, 10),
      );
    }
    final scaleX = current.width > 0 ? width / current.width : 1.0;
    final barHeight =
        height - (hasInterpretationLine ? interpretationLineHeight : 0);
    return copyWith(
      height: barHeight.clamp(10, 2000),
      moduleWidth: (moduleWidth * scaleX).round().clamp(1, 10),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'data': data,
        'symbology': type.name,
        'height': height,
        'orientation': orientation.name,
        'printInterpretationLine': printInterpretationLine,
        'printInterpretationLineAbove': printInterpretationLineAbove,
        'moduleWidth': moduleWidth,
        'magnification': magnification,
        'qrErrorCorrection': qrErrorCorrection.name,
      };

  factory BarcodeElement.fromJson(String id, Map<String, dynamic> json) {
    return BarcodeElement(
      id: id,
      x: intFromJson(json['x']) ?? 0,
      y: intFromJson(json['y']) ?? 0,
      data: stringFromJson(json['data']) ?? '',
      type: enumFromJson(
        ZplBarcodeType.values,
        json['symbology'],
        ZplBarcodeType.code128,
      ),
      height: intFromJson(json['height']) ?? 80,
      orientation: enumFromJson(
        ZplOrientation.values,
        json['orientation'],
        ZplOrientation.normal,
      ),
      printInterpretationLine: boolFromJson(json['printInterpretationLine'], true),
      printInterpretationLineAbove:
          boolFromJson(json['printInterpretationLineAbove'], false),
      moduleWidth: intFromJson(json['moduleWidth']) ?? 2,
      magnification: intFromJson(json['magnification']) ?? 3,
      qrErrorCorrection: enumFromJson(
        ZplQrErrorCorrection.values,
        json['qrErrorCorrection'],
        ZplQrErrorCorrection.medium,
      ),
    );
  }
}
