import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'canvas/zpl_label_canvas.dart';
import 'editor_controller.dart';
import 'editor_shortcuts.dart';
import 'panels/editor_toolbar.dart';
import 'panels/element_inspector.dart';
import 'storage/template_store.dart';

/// Complete editor: toolbar on top, canvas in the middle, inspector on the
/// right (or below on narrow layouts).
class ZplLabelEditor extends StatefulWidget {
  final EditorController controller;
  final Future<Uint8List?> Function()? onPickImage;

  /// Optional template persistence; without it the Templates button is hidden.
  final TemplateStore? templateStore;

  const ZplLabelEditor({
    super.key,
    required this.controller,
    this.onPickImage,
    this.templateStore,
  });

  @override
  State<ZplLabelEditor> createState() => _ZplLabelEditorState();
}

class _ZplLabelEditorState extends State<ZplLabelEditor> {
  final _canvasFocus = FocusNode(debugLabel: 'zpl-editor-canvas');

  @override
  void dispose() {
    _canvasFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    // Focus lands on the canvas when it is clicked, so arrow keys nudge
    // elements instead of moving the caret in an inspector field.
    // Shortcuts wrap only the canvas so typing in inspector fields never
    // nudges or deletes elements.
    final canvas = EditorShortcuts(
      controller: c,
      child: Focus(
        focusNode: _canvasFocus,
        child: Listener(
          onPointerDown: (_) => _canvasFocus.requestFocus(),
          child: ColoredBox(
            color: Colors.blueGrey.shade100,
            child: ZplLabelCanvas(controller: c),
          ),
        ),
      ),
    );
    final inspector = ElementInspector(controller: c);

    return Column(
      children: [
        EditorToolbar(
          controller: c,
          onPickImage: widget.onPickImage,
          templateStore: widget.templateStore,
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 700) {
                // Phone: canvas takes the full height; properties live in
                // a pull-up sheet that starts collapsed to a handle.
                return Stack(
                  children: [
                    Positioned.fill(child: canvas),
                    DraggableScrollableSheet(
                      initialChildSize: 0.12,
                      minChildSize: 0.12,
                      maxChildSize: 0.7,
                      snap: true,
                      snapSizes: const [0.12, 0.45, 0.7],
                      builder: (context, scroll) => Material(
                        elevation: 8,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ElementInspector(
                          controller: c,
                          scrollController: scroll,
                          header: const _SheetHandle(),
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: canvas),
                  SizedBox(width: 300, child: inspector),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
