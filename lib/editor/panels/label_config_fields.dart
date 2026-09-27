import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import '../editor_controller.dart';
import 'inspector_fields.dart';

/// Label-level settings (`^PW`, `^LL`, `~SD`, `^PR`).
class LabelConfigFields extends StatelessWidget {
  final EditorController controller;

  const LabelConfigFields({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller.config;
    ZplConfiguration rebuild({int? width, int? length, int? darkness, int? speed}) {
      return ZplConfiguration(
        printWidth: width ?? c.printWidth,
        labelLength: length ?? c.labelLength,
        darkness: darkness ?? c.darkness,
        printSpeed: speed ?? c.printSpeed,
        labelHomeX: c.labelHomeX,
        labelHomeY: c.labelHomeY,
        printMode: c.printMode,
        mediaType: c.mediaType,
        printOrientation: c.printOrientation,
        printDensity: c.printDensity,
        internationalEncoding: c.internationalEncoding,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text('LABEL', style: Theme.of(context).textTheme.labelLarge),
        Row(
          spacing: 8,
          children: [
            Expanded(child: IntField(label: 'Width (dots)', value: controller.document.width, min: 8, max: 4000, onChanged: (v) => controller.setConfig(rebuild(width: v)))),
            Expanded(child: IntField(label: 'Length (dots)', value: controller.document.height, min: 8, max: 8000, onChanged: (v) => controller.setConfig(rebuild(length: v)))),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(child: IntField(label: 'Darkness', value: c.darkness ?? 0, min: 0, max: 30, onChanged: (v) => controller.setConfig(rebuild(darkness: v)))),
            Expanded(child: IntField(label: 'Speed', value: c.printSpeed ?? 0, min: 0, max: 14, onChanged: (v) => controller.setConfig(rebuild(speed: v)))),
          ],
        ),
        Text('Select an element to edit its properties.', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
