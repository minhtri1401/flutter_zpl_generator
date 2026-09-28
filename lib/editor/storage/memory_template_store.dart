import '../model/label_document.dart';
import 'template_store.dart';

/// In-memory store; templates vanish when the app closes.
class MemoryTemplateStore implements TemplateStore {
  final Map<String, (TemplateInfo, LabelDocument)> _items = {};

  @override
  Future<List<TemplateInfo>> list() async {
    final infos = _items.values.map((e) => e.$1).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return infos;
  }

  @override
  Future<LabelDocument?> load(String id) async => _items[id]?.$2;

  @override
  Future<TemplateInfo> save(
    LabelDocument document, {
    String? id,
    required String name,
  }) async {
    final info = TemplateInfo(
      id: id ?? newTemplateId(),
      name: name,
      updatedAt: DateTime.now(),
    );
    _items[info.id] = (info, document);
    return info;
  }

  @override
  Future<void> delete(String id) async => _items.remove(id);
}
