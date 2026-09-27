import 'dart:ui';

import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'label_element.dart';

/// Editable text field mapping to [ZplText].
///
/// [fontHeight] and [fontWidth] are always explicit in the editor so resize
/// handles have something concrete to scale.
class TextElement extends LabelElement {
  final String text;
  final ZplFont font;
  final String? fontAlias;
  final int fontHeight;
  final int fontWidth;
  final ZplOrientation orientation;
  final ZplAlignment? alignment;
  final int maxLines;
  final int lineSpacing;
  final int? maxWidth;
  final bool reversePrint;

  const TextElement({
    required super.id,
    super.x = 0,
    super.y = 0,
    required this.text,
    this.font = ZplFont.zero,
    this.fontAlias,
    this.fontHeight = 30,
    this.fontWidth = 30,
    this.orientation = ZplOrientation.normal,
    this.alignment,
    this.maxLines = 1,
    this.lineSpacing = 0,
    this.maxWidth,
    this.reversePrint = false,
  });

  @override
  String get typeName => 'text';

  /// Average glyph advance of Zebra font 0 relative to the width parameter.
  static const double avgCharAdvance = 0.6;

  /// Alignment only has a defined `^FB` box when a wrap width exists;
  /// without one the package emitter re-anchors or drops it, so the editor
  /// treats alignment as "needs wrap width".
  ZplAlignment? get effectiveAlignment => maxWidth == null ? null : alignment;

  TextElement copyWith({
    int? x,
    int? y,
    String? text,
    ZplFont? font,
    String? Function()? fontAlias,
    int? fontHeight,
    int? fontWidth,
    ZplOrientation? orientation,
    ZplAlignment? Function()? alignment,
    int? maxLines,
    int? lineSpacing,
    int? Function()? maxWidth,
    bool? reversePrint,
  }) {
    return TextElement(
      id: id,
      x: x ?? this.x,
      y: y ?? this.y,
      text: text ?? this.text,
      font: font ?? this.font,
      fontAlias: fontAlias != null ? fontAlias() : this.fontAlias,
      fontHeight: fontHeight ?? this.fontHeight,
      fontWidth: fontWidth ?? this.fontWidth,
      orientation: orientation ?? this.orientation,
      alignment: alignment != null ? alignment() : this.alignment,
      maxLines: maxLines ?? this.maxLines,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      maxWidth: maxWidth != null ? maxWidth() : this.maxWidth,
      reversePrint: reversePrint ?? this.reversePrint,
    );
  }

  @override
  ZplText toCommand() => ZplText(
        x: x,
        y: y,
        text: text,
        font: font,
        fontAlias: fontAlias,
        fontHeight: fontHeight,
        fontWidth: fontWidth,
        orientation: orientation,
        alignment: effectiveAlignment,
        maxLines: maxLines,
        lineSpacing: lineSpacing,
        maxWidth: maxWidth,
        reversePrint: reversePrint,
      );

  @override
  Rect bounds(ZplConfiguration config) {
    // Width: wrap box when set, else the longest line's estimated advance.
    double width;
    if (maxWidth != null) {
      width = maxWidth!.toDouble();
    } else {
      var longest = 0;
      for (final line in text.split('\n')) {
        if (line.length > longest) longest = line.length;
      }
      width = (longest * fontWidth * avgCharAdvance).ceilToDouble().clamp(1, 1e6);
    }
    final lines = maxLines < 1 ? 1 : maxLines;
    final height = (fontHeight * lines + lineSpacing * (lines - 1)).toDouble();
    final size = orientedSize(orientation, width, height);
    return Rect.fromLTWH(x.toDouble(), y.toDouble(), size.width, size.height);
  }

  @override
  TextElement moveTo(int x, int y) => copyWith(x: x, y: y);

  /// Scales font height by the requested height and font width by the
  /// horizontal scale factor, keeping text single-source-of-truth.
  @override
  TextElement resizeTo(int width, int height) {
    // Handles work in oriented space; font metrics are un-oriented.
    final unoriented = orientedSize(orientation, width.toDouble(), height.toDouble());
    width = unoriented.width.round();
    height = unoriented.height.round();
    final current = bounds(const ZplConfiguration());
    final currentUnoriented = orientedSize(orientation, current.width, current.height);
    final lines = maxLines < 1 ? 1 : maxLines;
    final newHeight = ((height - lineSpacing * (lines - 1)) / lines)
        .round()
        .clamp(10, 1000);
    final scaleX = currentUnoriented.width > 0 ? width / currentUnoriented.width : 1.0;
    final newWidth = (fontWidth * scaleX).round().clamp(10, 1000);
    return copyWith(fontHeight: newHeight, fontWidth: newWidth);
  }

  @override
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'text': text,
        'font': font.name,
        'fontAlias': fontAlias,
        'fontHeight': fontHeight,
        'fontWidth': fontWidth,
        'orientation': orientation.name,
        'alignment': alignment?.name,
        'maxLines': maxLines,
        'lineSpacing': lineSpacing,
        'maxWidth': maxWidth,
        'reversePrint': reversePrint,
      };

  factory TextElement.fromJson(String id, Map<String, dynamic> json) {
    return TextElement(
      id: id,
      x: intFromJson(json['x']) ?? 0,
      y: intFromJson(json['y']) ?? 0,
      text: stringFromJson(json['text']) ?? '',
      font: enumFromJson(ZplFont.values, json['font'], ZplFont.zero),
      fontAlias: stringFromJson(json['fontAlias']),
      fontHeight: intFromJson(json['fontHeight']) ?? 30,
      fontWidth: intFromJson(json['fontWidth']) ?? 30,
      orientation: enumFromJson(
        ZplOrientation.values,
        json['orientation'],
        ZplOrientation.normal,
      ),
      alignment: json['alignment'] == null
          ? null
          : enumFromJson(
              ZplAlignment.values,
              json['alignment'],
              ZplAlignment.left,
            ),
      maxLines: intFromJson(json['maxLines']) ?? 1,
      lineSpacing: intFromJson(json['lineSpacing']) ?? 0,
      maxWidth: intFromJson(json['maxWidth']),
      reversePrint: boolFromJson(json['reversePrint'], false),
    );
  }
}
