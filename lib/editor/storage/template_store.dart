import 'dart:convert';

import '../model/label_document.dart';

/// Metadata for a saved template.
class TemplateInfo {
  final String id;
  final String name;
  final DateTime updatedAt;

  const TemplateInfo({
    required this.id,
    required this.name,
    required this.updatedAt,
  });

  @override
  bool operator ==(Object other) =>
      other is TemplateInfo && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// Where templates live. Implementations: [MemoryTemplateStore] (default,
/// tests) and `FileTemplateStore` (one JSON file per template; import its
/// file directly because it uses `dart:io`).
abstract class TemplateStore {
  Future<List<TemplateInfo>> list();

  Future<LabelDocument?> load(String id);

  /// Saves [document] under [name]; a null [id] creates a new template.
  Future<TemplateInfo> save(
    LabelDocument document, {
    String? id,
    required String name,
  });

  Future<void> delete(String id);
}

/// Envelope written by every store: `{version, name, updatedAt, document}`.
class TemplateEnvelope {
  static const int version = 1;

  static Map<String, dynamic> encode(
    String name,
    DateTime updatedAt,
    LabelDocument doc,
  ) => {
    'version': version,
    'name': name,
    'updatedAt': updatedAt.toIso8601String(),
    'document': doc.toJson(),
  };

  /// Returns null when [json] is not a template envelope or a bare document.
  static ({String? name, DateTime? updatedAt, LabelDocument document})? decode(
    Object? json,
  ) {
    if (json is! Map<String, dynamic>) return null;
    final rawDoc = json['document'];
    if (rawDoc is Map<String, dynamic>) {
      return (
        name: json['name'] is String ? json['name'] as String : null,
        updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
        document: LabelDocument.fromJson(rawDoc),
      );
    }
    // A bare document (LabelDocument.toJson) is accepted too.
    if (json['elements'] is List) {
      return (
        name: null,
        updatedAt: null,
        document: LabelDocument.fromJson(json),
      );
    }
    return null;
  }

  static String encodeString(
    String name,
    DateTime updatedAt,
    LabelDocument doc,
  ) => const JsonEncoder.withIndent('  ').convert(encode(name, updatedAt, doc));

  static ({String? name, DateTime? updatedAt, LabelDocument document})?
  decodeString(String text) {
    try {
      return decode(jsonDecode(text));
    } on FormatException {
      return null;
    }
  }
}

/// Simple unique ids without an external dependency.
String newTemplateId() =>
    'tpl-${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}';
