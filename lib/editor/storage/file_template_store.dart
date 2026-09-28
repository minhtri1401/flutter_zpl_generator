import 'dart:convert';
import 'dart:io';

import '../model/label_document.dart';
import 'template_store.dart';

/// One `<id>.json` file per template inside [directory]. Uses `dart:io`, so
/// it is not exported from the barrel; import this file where supported.
class FileTemplateStore implements TemplateStore {
  final Directory directory;

  FileTemplateStore(this.directory);

  File _file(String id) =>
      File('${directory.path}${Platform.pathSeparator}$id.json');

  @override
  Future<List<TemplateInfo>> list() async {
    if (!await directory.exists()) return const [];
    final infos = <TemplateInfo>[];
    await for (final entity in directory.list()) {
      if (entity is! File || !entity.path.endsWith('.json')) continue;
      try {
        final env = TemplateEnvelope.decodeString(await entity.readAsString());
        if (env == null) continue;
        final id = entity.uri.pathSegments.last.replaceAll('.json', '');
        infos.add(
          TemplateInfo(
            id: id,
            name: env.name ?? id,
            updatedAt: env.updatedAt ?? (await entity.lastModified()),
          ),
        );
      } on IOException {
        continue; // unreadable file: skip rather than fail the listing
      }
    }
    infos.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return infos;
  }

  @override
  Future<LabelDocument?> load(String id) async {
    final f = _file(id);
    if (!await f.exists()) return null;
    return TemplateEnvelope.decodeString(await f.readAsString())?.document;
  }

  @override
  Future<TemplateInfo> save(
    LabelDocument document, {
    String? id,
    required String name,
  }) async {
    await directory.create(recursive: true);
    final info = TemplateInfo(
      id: id ?? newTemplateId(),
      name: name,
      updatedAt: DateTime.now(),
    );
    await _file(info.id).writeAsString(
      jsonEncode(TemplateEnvelope.encode(info.name, info.updatedAt, document)),
      flush: true,
    );
    return info;
  }

  @override
  Future<void> delete(String id) async {
    final f = _file(id);
    if (await f.exists()) await f.delete();
  }
}
