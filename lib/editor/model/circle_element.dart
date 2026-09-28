import 'dart:ui';

import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'label_element.dart';

/// Editable circle mapping to [ZplGraphicCircle] (`^GC`).
class CircleElement extends LabelElement {
  final int diameter;
  final int borderThickness;

  const CircleElement({
    required super.id,
    super.x = 0,
    super.y = 0,
    this.diameter = 100,
    this.borderThickness = 2,
  });

  @override
  String get typeName => 'circle';

  CircleElement copyWith({
    int? x,
    int? y,
    int? diameter,
    int? borderThickness,
  }) {
    return CircleElement(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      diameter: diameter ?? this.diameter,
      borderThickness: borderThickness ?? this.borderThickness,
    );
  }

  @override
  ZplGraphicCircle toCommand() => ZplGraphicCircle(
    x: x,
    y: y,
    diameter: diameter,
    borderThickness: borderThickness,
  );

  @override
  Rect bounds(ZplConfiguration config) => Rect.fromLTWH(
    x.toDouble(),
    y.toDouble(),
    diameter.toDouble(),
    diameter.toDouble(),
  );

  @override
  CircleElement moveTo(int x, int y) => copyWith(x: x, y: y);

  /// Circles stay circular: diameter follows the smaller side.
  @override
  CircleElement resizeTo(int width, int height) =>
      copyWith(diameter: (width < height ? width : height).clamp(3, 4095));

  @override
  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'diameter': diameter,
    'borderThickness': borderThickness,
  };

  factory CircleElement.fromJson(String id, Map<String, dynamic> json) {
    return CircleElement(
      id: id,
      x: intFromJson(json['x']) ?? 0,
      y: intFromJson(json['y']) ?? 0,
      diameter: intFromJson(json['diameter']) ?? 100,
      borderThickness: intFromJson(json['borderThickness']) ?? 2,
    );
  }
}
