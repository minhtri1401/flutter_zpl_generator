import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'element_json_codec.dart';
import 'label_element.dart';
import 'label_variables.dart';

/// Immutable editor document: label configuration plus ordered elements.
///
/// Element order is both paint order and ZPL emission order. All mutations
/// return a new document so undo/redo can keep plain snapshots.
class LabelDocument {
  static const int schemaVersion = 1;

  /// 4x6" label at 203 dpi.
  static const ZplConfiguration defaultConfig = ZplConfiguration(
    printWidth: 812,
    labelLength: 1218,
  );

  final ZplConfiguration config;
  final List<LabelElement> elements;

  /// Sample values for `{{placeholders}}`, used by the export preview and
  /// remembered with the template.
  final Map<String, String> sampleData;

  const LabelDocument({
    this.config = defaultConfig,
    this.elements = const [],
    this.sampleData = const {},
  });

  /// Placeholder names used by text and barcode elements, in order.
  List<String> get variables => LabelVariables.scan(this);

  /// Label size in dots with the same fallbacks as [ZplNativePreview].
  int get width => config.printWidth ?? 406;
  int get height => config.labelLength ?? 609;

  LabelDocument copyWith({
    ZplConfiguration? config,
    List<LabelElement>? elements,
    Map<String, String>? sampleData,
  }) {
    return LabelDocument(
      config: config ?? this.config,
      elements: elements ?? this.elements,
      sampleData: sampleData ?? this.sampleData,
    );
  }

  LabelDocument withSample(String name, String value) =>
      copyWith(sampleData: {...sampleData, name: value});

  /// ZPL with [data] (default: [sampleData]) substituted into placeholders.
  /// Placeholders without a value are left as-is.
  Future<String> buildBoundZpl([Map<String, String>? data]) =>
      ZplTemplate(toGenerator()).bind(data ?? sampleData);

  LabelElement? elementById(String id) {
    for (final e in elements) {
      if (e.id == id) return e;
    }
    return null;
  }

  LabelDocument add(LabelElement element) =>
      copyWith(elements: [...elements, element]);

  LabelDocument remove(String id) =>
      copyWith(elements: elements.where((e) => e.id != id).toList());

  /// Replaces the element with [id] using [update]; no-op if absent.
  LabelDocument update(
    String id,
    LabelElement Function(LabelElement element) update,
  ) {
    return copyWith(
      elements: [for (final e in elements) e.id == id ? update(e) : e],
    );
  }

  /// Moves [id] one step towards the end (painted later = on top).
  LabelDocument bringForward(String id) => _shift(id, 1);

  LabelDocument sendBackward(String id) => _shift(id, -1);

  LabelDocument _shift(String id, int delta) {
    final index = elements.indexWhere((e) => e.id == id);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= elements.length) return this;
    final list = [...elements];
    final item = list.removeAt(index);
    list.insert(target, item);
    return copyWith(elements: list);
  }

  /// Bridges to the package: every element becomes its [ZplCommand].
  ZplGenerator toGenerator() => ZplGenerator(
    config: config,
    commands: elements.map((e) => e.toCommand()).toList(),
  );

  Future<String> buildZpl() => toGenerator().build();

  Map<String, dynamic> toJson() => {
    'version': schemaVersion,
    'config': _configToJson(config),
    'elements': elements.map(ElementJsonCodec.encode).toList(),
    if (sampleData.isNotEmpty) 'sampleData': sampleData,
  };

  factory LabelDocument.fromJson(Map<String, dynamic> json) {
    final rawElements = json['elements'];
    final elements = <LabelElement>[];
    if (rawElements is List) {
      for (final raw in rawElements) {
        if (raw is! Map<String, dynamic>) continue;
        // A malformed element must not take the whole document down.
        try {
          final decoded = ElementJsonCodec.decode(raw);
          if (decoded != null) elements.add(decoded);
        } catch (_) {
          continue;
        }
      }
    }
    final rawConfig = json['config'];
    final rawSample = json['sampleData'];
    return LabelDocument(
      config: rawConfig is Map<String, dynamic>
          ? _configFromJson(rawConfig)
          : defaultConfig,
      elements: elements,
      sampleData: rawSample is Map
          ? {
              for (final e in rawSample.entries)
                if (e.key is String) e.key as String: e.value.toString(),
            }
          : const {},
    );
  }

  static Map<String, dynamic> _configToJson(ZplConfiguration c) => {
    'printWidth': c.printWidth,
    'labelLength': c.labelLength,
    'darkness': c.darkness,
    'printSpeed': c.printSpeed,
    'labelHomeX': c.labelHomeX,
    'labelHomeY': c.labelHomeY,
    'printDensity': c.printDensity?.name,
    'printMode': c.printMode?.name,
    'mediaType': c.mediaType?.name,
    'printOrientation': c.printOrientation?.name,
    'internationalEncoding': c.internationalEncoding,
  };

  static ZplConfiguration _configFromJson(Map<String, dynamic> j) {
    T? optEnum<T extends Enum>(List<T> values, Object? raw) {
      if (raw is! String) return null;
      for (final v in values) {
        if (v.name == raw) return v;
      }
      return null;
    }

    return ZplConfiguration(
      printWidth: intFromJson(j['printWidth']),
      labelLength: intFromJson(j['labelLength']),
      darkness: intFromJson(j['darkness']),
      printSpeed: intFromJson(j['printSpeed']),
      labelHomeX: intFromJson(j['labelHomeX']),
      labelHomeY: intFromJson(j['labelHomeY']),
      printDensity: optEnum(ZplPrintDensity.values, j['printDensity']),
      printMode: optEnum(ZplPrintMode.values, j['printMode']),
      mediaType: optEnum(ZplMediaType.values, j['mediaType']),
      printOrientation: optEnum(
        ZplPrintOrientation.values,
        j['printOrientation'],
      ),
      internationalEncoding: intFromJson(j['internationalEncoding']),
    );
  }
}
