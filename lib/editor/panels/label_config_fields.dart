import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import '../editor_controller.dart';
import '../model/label_preset.dart';
import 'inspector_fields.dart';

/// Label-level settings: stock preset, density, units, size, darkness, speed.
class LabelConfigFields extends StatelessWidget {
  final EditorController controller;

  const LabelConfigFields({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = controller.config;
    final dpmm = controller.dpmm;
    final showUnits = controller.units != EditorUnits.dots;
    final preset = LabelPreset.matching(
      controller.document.width,
      controller.document.height,
      dpmm,
    );

    ZplConfiguration rebuild({
      int? width,
      int? length,
      int? darkness,
      int? speed,
      ZplPrintDensity? density,
    }) {
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
        printDensity: density ?? c.printDensity,
        internationalEncoding: c.internationalEncoding,
      );
    }

    void applyPreset(LabelPreset? p, double atDpmm) {
      if (p == null) return;
      controller.setConfig(
        rebuild(width: p.widthDots(atDpmm), length: p.heightDots(atDpmm)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Text('LABEL', style: Theme.of(context).textTheme.labelLarge),
        DropdownButtonFormField<LabelPreset?>(
          isExpanded: true,
          initialValue: preset,
          decoration: const InputDecoration(
            labelText: 'Stock preset',
            isDense: true,
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('Custom')),
            for (final p in LabelPreset.all)
              DropdownMenuItem(value: p, child: Text(p.name)),
          ],
          onChanged: (p) => applyPreset(p, dpmm),
        ),
        DropdownButtonFormField<ZplPrintDensity>(
          isExpanded: true,
          initialValue: c.printDensity ?? ZplPrintDensity.d8,
          decoration: const InputDecoration(
            labelText: 'Density',
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: ZplPrintDensity.d8, child: Text('203 dpi')),
            DropdownMenuItem(
              value: ZplPrintDensity.d12,
              child: Text('300 dpi'),
            ),
          ],
          onChanged: (d) {
            if (d == null) return;
            // Keep the physical size when the density changes.
            final newDpmm = dpmmFor(d);
            final w = (controller.document.width / dpmm * newDpmm).round();
            final h = (controller.document.height / dpmm * newDpmm).round();
            controller.setConfig(rebuild(density: d, width: w, length: h));
          },
        ),
        SegmentedButton<EditorUnits>(
          showSelectedIcon: false,
          segments: [
            for (final u in EditorUnits.values)
              ButtonSegment(value: u, label: Text(u.label)),
          ],
          selected: {controller.units},
          onSelectionChanged: (s) => controller.units = s.first,
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: IntField(
                label: 'Width (dots)',
                value: controller.document.width,
                min: 8,
                max: 4000,
                helperText: showUnits
                    ? controller.formatDots(controller.document.width)
                    : null,
                onChanged: (v) => controller.setConfig(rebuild(width: v)),
              ),
            ),
            Expanded(
              child: IntField(
                label: 'Length (dots)',
                value: controller.document.height,
                min: 8,
                max: 8000,
                helperText: showUnits
                    ? controller.formatDots(controller.document.height)
                    : null,
                onChanged: (v) => controller.setConfig(rebuild(length: v)),
              ),
            ),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: IntField(
                label: 'Darkness',
                value: c.darkness ?? 0,
                min: 0,
                max: 30,
                onChanged: (v) => controller.setConfig(rebuild(darkness: v)),
              ),
            ),
            Expanded(
              child: IntField(
                label: 'Speed',
                value: c.printSpeed ?? 0,
                min: 0,
                max: 14,
                onChanged: (v) => controller.setConfig(rebuild(speed: v)),
              ),
            ),
          ],
        ),
        Text(
          'Select an element to edit its properties.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
