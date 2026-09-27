import 'dart:ui';

import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'label_element.dart';

/// Straight horizontal or vertical rule mapping to a box-type [ZplSeparator].
class LineElement extends LabelElement {
  final int length;
  final int thickness;
  final bool vertical;

  const LineElement({
    required super.id,
    super.x = 0,
    super.y = 0,
    this.length = 200,
    this.thickness = 2,
    this.vertical = false,
  });

  @override
  String get typeName => 'line';

  LineElement copyWith({
    int? x,
    int? y,
    int? length,
    int? thickness,
    bool? vertical,
  }) {
    return LineElement(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      length: length ?? this.length,
      thickness: thickness ?? this.thickness,
      vertical: vertical ?? this.vertical,
    );
  }

  @override
  ZplSeparator toCommand() => ZplSeparator(
        x: x,
        y: y,
        type: ZplSeparatorType.box,
        thickness: thickness.clamp(1, 32000),
        length: length.clamp(1, 32000),
        orientation:
            vertical ? ZplOrientation.rotated90 : ZplOrientation.normal,
      );

  @override
  Rect bounds(ZplConfiguration config) => Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        (vertical ? thickness : length).toDouble(),
        (vertical ? length : thickness).toDouble(),
      );

  @override
  LineElement moveTo(int x, int y) => copyWith(x: x, y: y);

  /// Length follows the axis of the line; thickness follows the other axis.
  @override
  LineElement resizeTo(int width, int height) => copyWith(
        length: (vertical ? height : width).clamp(1, 32000),
        thickness: (vertical ? width : height).clamp(1, 32000),
      );

  @override
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'length': length,
        'thickness': thickness,
        'vertical': vertical,
      };

  factory LineElement.fromJson(String id, Map<String, dynamic> json) {
    return LineElement(
      id: id,
      x: intFromJson(json['x']) ?? 0,
      y: intFromJson(json['y']) ?? 0,
      length: intFromJson(json['length']) ?? 200,
      thickness: intFromJson(json['thickness']) ?? 2,
      vertical: boolFromJson(json['vertical'], false),
    );
  }
}
