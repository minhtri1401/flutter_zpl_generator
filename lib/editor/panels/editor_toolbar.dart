import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../editor_controller.dart';
import '../model/barcode_element.dart';
import '../model/box_element.dart';
import '../model/circle_element.dart';
import '../model/image_element.dart';
import '../model/label_element.dart';
import '../model/line_element.dart';
import '../model/text_element.dart';
import '../storage/template_store.dart';
import 'templates_sheet.dart';
import 'zpl_export_dialog.dart';

/// Add / edit / history / export actions. Image picking is delegated to the
/// host via [onPickImage] so the editor stays free of platform plugins.
class EditorToolbar extends StatelessWidget {
  final EditorController controller;
  final Future<Uint8List?> Function()? onPickImage;

  /// When set, a Templates button offers save/load/import/export.
  final TemplateStore? templateStore;

  const EditorToolbar({
    super.key,
    required this.controller,
    this.onPickImage,
    this.templateStore,
  });

  static const _origin = 32;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final hasSelection = c.selected != null;
        return Material(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 4,
                children: [
                  _add(
                    context,
                    Icons.text_fields,
                    'Text',
                    () => TextElement(
                      id: ElementId.next('text'),
                      x: _origin,
                      y: _origin,
                      text: 'Text',
                    ),
                  ),
                  _add(
                    context,
                    Icons.qr_code_2,
                    'Barcode',
                    () => BarcodeElement(
                      id: ElementId.next('barcode'),
                      x: _origin,
                      y: _origin,
                      data: '123456789012',
                    ),
                  ),
                  _add(
                    context,
                    Icons.crop_square,
                    'Box',
                    () => BoxElement(
                      id: ElementId.next('box'),
                      x: _origin,
                      y: _origin,
                    ),
                  ),
                  _add(
                    context,
                    Icons.horizontal_rule,
                    'Line',
                    () => LineElement(
                      id: ElementId.next('line'),
                      x: _origin,
                      y: _origin,
                    ),
                  ),
                  _add(
                    context,
                    Icons.circle_outlined,
                    'Circle',
                    () => CircleElement(
                      id: ElementId.next('circle'),
                      x: _origin,
                      y: _origin,
                    ),
                  ),
                  if (onPickImage != null)
                    IconButton(
                      tooltip: 'Image',
                      icon: const Icon(Icons.image_outlined),
                      onPressed: () => _pickImage(context),
                    ),
                  const VerticalDivider(width: 16),
                  IconButton(
                    tooltip: 'Undo',
                    icon: const Icon(Icons.undo),
                    onPressed: c.canUndo ? c.undo : null,
                  ),
                  IconButton(
                    tooltip: 'Redo',
                    icon: const Icon(Icons.redo),
                    onPressed: c.canRedo ? c.redo : null,
                  ),
                  IconButton(
                    tooltip: 'Duplicate',
                    icon: const Icon(Icons.content_copy),
                    onPressed: hasSelection ? c.duplicateSelected : null,
                  ),
                  IconButton(
                    tooltip: 'Bring forward',
                    icon: const Icon(Icons.flip_to_front),
                    onPressed: hasSelection ? c.bringForward : null,
                  ),
                  IconButton(
                    tooltip: 'Send backward',
                    icon: const Icon(Icons.flip_to_back),
                    onPressed: hasSelection ? c.sendBackward : null,
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: hasSelection ? c.removeSelected : null,
                  ),
                  const VerticalDivider(width: 16),
                  IconButton(
                    tooltip:
                        'Multi-select (tap to add, drag empty space to marquee)',
                    isSelected: c.multiSelectMode,
                    icon: const Icon(Icons.highlight_alt),
                    selectedIcon: const Icon(
                      Icons.highlight_alt,
                      color: Colors.blueAccent,
                    ),
                    onPressed: () => c.multiSelectMode = !c.multiSelectMode,
                  ),
                  PopupMenuButton<Object>(
                    tooltip: 'Align',
                    icon: const Icon(Icons.align_horizontal_left),
                    onSelected: (v) =>
                        v is AlignOp ? c.alignSelected(v) : c.selectAll(),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'all',
                        child: Text('Select all'),
                      ),
                      const PopupMenuDivider(),
                      for (final op in AlignOp.values)
                        PopupMenuItem(
                          value: op,
                          enabled:
                              hasSelection &&
                              (!op.isDistribute || c.canDistribute),
                          child: Text(op.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 16),
                  if (templateStore != null)
                    IconButton(
                      tooltip: 'Templates',
                      icon: const Icon(Icons.folder_open),
                      onPressed: () =>
                          TemplatesSheet.show(context, c, templateStore!),
                    ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.code),
                    label: const Text('ZPL'),
                    onPressed: () => ZplExportDialog.show(context, c),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _add(
    BuildContext context,
    IconData icon,
    String tip,
    LabelElement Function() make,
  ) {
    return IconButton(
      tooltip: 'Add $tip',
      icon: Icon(icon),
      onPressed: () => controller.addElement(make()),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final bytes = await onPickImage!();
    if (bytes == null || bytes.isEmpty) return;
    controller.addElement(
      ImageElement(
        id: ElementId.next('image'),
        x: _origin,
        y: _origin,
        image: bytes,
        targetWidth: 200,
        targetHeight: 200,
      ),
    );
  }
}
