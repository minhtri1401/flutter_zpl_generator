import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'label_element.dart';

/// Editable raster image mapping to [ZplImageInline] (`^GFA`).
///
/// [targetWidth]/[targetHeight] are always explicit so bounds are known
/// without decoding the image, and aspect is not kept by default so the
/// printed bitmap fills exactly the handle box. Bytes are persisted as base64.
class ImageElement extends LabelElement {
  final Uint8List image;
  final int targetWidth;
  final int targetHeight;
  final bool maintainAspect;
  final ZplDitheringAlgorithm ditheringAlgorithm;

  const ImageElement({
    required super.id,
    super.x = 0,
    super.y = 0,
    required this.image,
    required this.targetWidth,
    required this.targetHeight,
    this.maintainAspect = false,
    this.ditheringAlgorithm = ZplDitheringAlgorithm.floydSteinberg,
  });

  @override
  String get typeName => 'image';

  ImageElement copyWith({
    int? x,
    int? y,
    Uint8List? image,
    int? targetWidth,
    int? targetHeight,
    bool? maintainAspect,
    ZplDitheringAlgorithm? ditheringAlgorithm,
  }) {
    return ImageElement(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      image: image ?? this.image,
      targetWidth: targetWidth ?? this.targetWidth,
      targetHeight: targetHeight ?? this.targetHeight,
      maintainAspect: maintainAspect ?? this.maintainAspect,
      ditheringAlgorithm: ditheringAlgorithm ?? this.ditheringAlgorithm,
    );
  }

  /// The package caches decode/dither per [ZplImageInline] instance, so the
  /// command is memoised per element instance (elements are immutable).
  static final Expando<ZplImageInline> _commandCache = Expando();

  @override
  ZplImageInline toCommand() => _commandCache[this] ??= ZplImageInline(
        x: x,
        y: y,
        image: image,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        maintainAspect: maintainAspect,
        ditheringAlgorithm: ditheringAlgorithm,
      );

  @override
  Rect bounds(ZplConfiguration config) => Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        targetWidth.toDouble(),
        targetHeight.toDouble(),
      );

  @override
  ImageElement moveTo(int x, int y) => copyWith(x: x, y: y);

  @override
  ImageElement resizeTo(int width, int height) => copyWith(
        targetWidth: width.clamp(1, 32000),
        targetHeight: height.clamp(1, 32000),
      );

  @override
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'image': base64Encode(image),
        'targetWidth': targetWidth,
        'targetHeight': targetHeight,
        'maintainAspect': maintainAspect,
        'ditheringAlgorithm': ditheringAlgorithm.name,
      };

  factory ImageElement.fromJson(String id, Map<String, dynamic> json) {
    final raw = json['image'];
    Uint8List bytes;
    try {
      bytes = raw is String ? base64Decode(raw) : Uint8List(0);
    } on FormatException {
      bytes = Uint8List(0);
    }
    return ImageElement(
      id: id,
      x: intFromJson(json['x']) ?? 0,
      y: intFromJson(json['y']) ?? 0,
      image: bytes,
      targetWidth: intFromJson(json['targetWidth']) ?? 100,
      targetHeight: intFromJson(json['targetHeight']) ?? 100,
      maintainAspect: boolFromJson(json['maintainAspect'], false),
      ditheringAlgorithm: enumFromJson(
        ZplDitheringAlgorithm.values,
        json['ditheringAlgorithm'],
        ZplDitheringAlgorithm.floydSteinberg,
      ),
    );
  }
}
