import 'dart:ui';

import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'label_element.dart';

/// Editable rectangle mapping to [ZplBox] (`^GB`).
class BoxElement extends LabelElement {
  final int width;
  final int height;
  final int borderThickness;
  final int cornerRounding;
  final bool reversePrint;

  const BoxElement({
    required super.id,
    super.x = 0,
    super.y = 0,
    this.width = 200,
    this.height = 100,
    this.borderThickness = 2,
    this.cornerRounding = 0,
    this.reversePrint = false,
  });

  @override
  String get typeName => 'box';

  BoxElement copyWith({
    int? x,
    int? y,
    int? width,
    int? height,
    int? borderThickness,
    int? cornerRounding,
    bool? reversePrint,
  }) {
    return BoxElement(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      borderThickness: borderThickness ?? this.borderThickness,
      cornerRounding: cornerRounding ?? this.cornerRounding,
      reversePrint: reversePrint ?? this.reversePrint,
    );
  }

  @override
  ZplBox toCommand() => ZplBox(
        x: x,
        y: y,
        width: width,
        height: height,
        borderThickness: borderThickness.clamp(1, 32000),
        cornerRounding: cornerRounding.clamp(0, 8),
        reversePrint: reversePrint,
      );

  @override
  Rect bounds(ZplConfiguration config) => Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        width.toDouble(),
        height.toDouble(),
      );

  @override
  BoxElement moveTo(int x, int y) => copyWith(x: x, y: y);

  @override
  BoxElement resizeTo(int width, int height) =>
      copyWith(width: width.clamp(1, 32000), height: height.clamp(1, 32000));

  @override
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'borderThickness': borderThickness,
        'cornerRounding': cornerRounding,
        'reversePrint': reversePrint,
      };

  factory BoxElement.fromJson(String id, Map<String, dynamic> json) {
    return BoxElement(
      id: id,
      x: intFromJson(json['x']) ?? 0,
      y: intFromJson(json['y']) ?? 0,
      width: intFromJson(json['width']) ?? 200,
      height: intFromJson(json['height']) ?? 100,
      borderThickness: intFromJson(json['borderThickness']) ?? 2,
      cornerRounding: intFromJson(json['cornerRounding']) ?? 0,
      reversePrint: boolFromJson(json['reversePrint'], false),
    );
  }
}
