import 'package:flutter/material.dart';

import '../editor_controller.dart';
import '../model/barcode_element.dart';
import '../model/box_element.dart';
import '../model/circle_element.dart';
import '../model/image_element.dart';
import '../model/label_element.dart';
import '../model/line_element.dart';
import '../model/text_element.dart';
import 'inspector_fields.dart';
import 'label_config_fields.dart';
import 'shape_image_inspector.dart';
import 'text_barcode_inspector.dart';

/// Right-hand panel: label settings when nothing is selected, otherwise the
/// selected element's position plus its type-specific fields.
class ElementInspector extends StatelessWidget {
  final EditorController controller;

  /// Scroll controller from a [DraggableScrollableSheet], when hosted there.
  final ScrollController? scrollController;

  /// Optional widget shown above the fields (e.g. a sheet drag handle).
  final Widget? header;

  const ElementInspector({
    super.key,
    required this.controller,
    this.scrollController,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final e = controller.selected;
        final body = e == null
              ? LabelConfigFields(controller: controller)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 8,
                  children: [
                    Text(e.typeName.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge),
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(child: IntField(label: 'X', value: e.x, min: 0, onChanged: (v) => controller.updateSelected((el) => el.moveTo(v, el.y), coalesce: 'inspector:${e.id}'))),
                        Expanded(child: IntField(label: 'Y', value: e.y, min: 0, onChanged: (v) => controller.updateSelected((el) => el.moveTo(el.x, v), coalesce: 'inspector:${e.id}'))),
                      ],
                    ),
                    _fieldsFor(e),
                  ],
                );
        return SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(12),
          child: header == null
              ? body
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [header!, body],
                ),
        );
      },
    );
  }

  Widget _fieldsFor(LabelElement e) {
    // Edits to one element from the inspector merge into a single undo step.
    void apply(LabelElement updated) =>
        controller.updateSelected((_) => updated, coalesce: 'inspector:${e.id}');
    return switch (e) {
      TextElement() => TextInspector(e: e, onChanged: apply),
      BarcodeElement() => BarcodeInspector(e: e, onChanged: apply),
      BoxElement() => BoxInspector(e: e, onChanged: apply),
      CircleElement() => CircleInspector(e: e, onChanged: apply),
      LineElement() => LineInspector(e: e, onChanged: apply),
      ImageElement() => ImageInspector(e: e, onChanged: apply),
      _ => const SizedBox.shrink(),
    };
  }
}
