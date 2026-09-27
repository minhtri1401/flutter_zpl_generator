import 'dart:ui';

import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

/// Base type for every editable element on the label canvas.
///
/// Elements are immutable value objects with a stable [id]. Editing operations
/// return a new instance via [copyWith]-style helpers ([moveTo], [resizeTo]).
/// Each element maps 1:1 to an existing [ZplCommand] through [toCommand], so
/// ZPL export reuses the package emitters and adds no new ZPL logic.
abstract class LabelElement {
  /// Stable identity used for selection, hit-testing and undo history.
  final String id;

  /// Top-left origin in dots (maps to `^FO`).
  final int x;
  final int y;

  const LabelElement({required this.id, required this.x, required this.y});

  /// Discriminator persisted in JSON.
  String get typeName;

  /// Bounding rectangle in dots, used for hit-testing and selection handles.
  Rect bounds(ZplConfiguration config);

  /// The package command that emits this element's ZPL.
  ZplCommand toCommand();

  /// Returns a copy positioned at ([x], [y]).
  LabelElement moveTo(int x, int y);

  /// Returns a copy sized to roughly [width] x [height] dots. Each subtype
  /// decides which properties change (font size, module width, box size ...).
  LabelElement resizeTo(int width, int height);

  /// Element-specific JSON payload (without `type`/`id`, added by the codec).
  Map<String, dynamic> toJson();
}

/// Generates unique element ids without an external uuid dependency.
class ElementId {
  static int _counter = 0;

  static String next(String prefix) {
    _counter++;
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}-$_counter';
  }
}

/// Shared helpers for enum (de)serialisation.
T enumFromJson<T extends Enum>(List<T> values, Object? raw, T fallback) {
  if (raw is! String) return fallback;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  return fallback;
}

String? stringFromJson(Object? raw) => raw is String ? raw : null;

bool boolFromJson(Object? raw, bool fallback) => raw is bool ? raw : fallback;

/// Reads an int from JSON tolerating doubles and nulls.
int? intFromJson(Object? raw) {
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  return null;
}

/// Swaps width/height for 90/270 degree orientations.
Size orientedSize(ZplOrientation orientation, double width, double height) {
  return switch (orientation) {
    ZplOrientation.rotated90 ||
    ZplOrientation.readFromBottomUp270 => Size(height, width),
    _ => Size(width, height),
  };
}
