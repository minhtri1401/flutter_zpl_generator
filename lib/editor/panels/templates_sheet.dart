import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../editor_controller.dart';
import '../storage/template_store.dart';

/// Bottom sheet: save / save as / load / delete templates, plus JSON
/// export to the clipboard and import from pasted text.
class TemplatesSheet extends StatefulWidget {
  final EditorController controller;
  final TemplateStore store;

  const TemplatesSheet({
    super.key,
    required this.controller,
    required this.store,
  });

  static Future<void> show(
    BuildContext context,
    EditorController controller,
    TemplateStore store,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TemplatesSheet(controller: controller, store: store),
    );
  }

  @override
  State<TemplatesSheet> createState() => _TemplatesSheetState();
}

class _TemplatesSheetState extends State<TemplatesSheet> {
  late Future<List<TemplateInfo>> _list = widget.store.list();

  void _refresh() => setState(() => _list = widget.store.list());

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<String?> _askName(String initial) {
    final text = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Template name'),
        content: TextField(
          controller: text,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, text.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _save({required bool asNew}) async {
    final c = widget.controller;
    final current = c.currentTemplate;
    String? name = current?.name;
    if (asNew || name == null) {
      name = await _askName(name ?? 'Label');
      if (name == null || name.isEmpty) return;
    }
    try {
      final info = await widget.store.save(
        c.document,
        id: asNew ? null : current?.id,
        name: name,
      );
      c.markSaved(info);
      _toast('Saved "${info.name}"');
      _refresh();
    } catch (e) {
      _toast('Save failed: $e');
    }
  }

  Future<void> _load(TemplateInfo info) async {
    try {
      final doc = await widget.store.load(info.id);
      if (doc == null) return _toast('Template not found');
      widget.controller.loadTemplate(info, doc);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _toast('Load failed: $e');
    }
  }

  Future<void> _delete(TemplateInfo info) async {
    await widget.store.delete(info.id);
    if (widget.controller.currentTemplate?.id == info.id) {
      widget.controller.markSaved(null);
    }
    _refresh();
  }

  Future<void> _export() async {
    final c = widget.controller;
    final text = TemplateEnvelope.encodeString(
      c.currentTemplate?.name ?? 'Label',
      DateTime.now(),
      c.document,
    );
    await Clipboard.setData(ClipboardData(text: text));
    _toast('Template JSON copied to clipboard');
  }

  Future<void> _import() async {
    final text = TextEditingController();
    final pasted = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import template JSON'),
        content: TextField(
          controller: text,
          maxLines: 8,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Paste JSON here'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, text.text),
            child: const Text('Import'),
          ),
        ],
      ),
    );
    if (pasted == null || pasted.trim().isEmpty) return;
    final env = TemplateEnvelope.decodeString(pasted);
    if (env == null) return _toast('Not a valid template JSON');
    widget.controller.loadTemplate(null, env.document);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.controller.currentTemplate;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            Text(
              current == null ? 'Unsaved label' : 'Current: ${current.name}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => _save(asNew: false),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
                OutlinedButton(
                  onPressed: () => _save(asNew: true),
                  child: const Text('Save as…'),
                ),
                OutlinedButton.icon(
                  onPressed: _export,
                  icon: const Icon(Icons.copy),
                  label: const Text('Export JSON'),
                ),
                OutlinedButton.icon(
                  onPressed: _import,
                  icon: const Icon(Icons.paste),
                  label: const Text('Import JSON'),
                ),
              ],
            ),
            const Divider(),
            Flexible(
              child: FutureBuilder<List<TemplateInfo>>(
                future: _list,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Text('Could not list templates: ${snap.error}');
                  }
                  final items = snap.data;
                  if (items == null) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No saved templates yet.'),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final t = items[i];
                      return ListTile(
                        leading: Icon(
                          t.id == current?.id
                              ? Icons.radio_button_checked
                              : Icons.description_outlined,
                        ),
                        title: Text(t.name),
                        subtitle: Text(
                          t.updatedAt.toLocal().toString().substring(0, 16),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete',
                          onPressed: () => _delete(t),
                        ),
                        onTap: () => _load(t),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
