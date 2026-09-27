import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import '../model/box_element.dart';
import '../model/circle_element.dart';
import '../model/image_element.dart';
import '../model/line_element.dart';
import 'inspector_fields.dart';

class BoxInspector extends StatelessWidget {
  final BoxElement e;
  final ValueChanged<BoxElement> onChanged;
  const BoxInspector({super.key, required this.e, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(child: IntField(label: 'Width', value: e.width, min: 1, max: 32000, onChanged: (v) => onChanged(e.copyWith(width: v)))),
            Expanded(child: IntField(label: 'Height', value: e.height, min: 1, max: 32000, onChanged: (v) => onChanged(e.copyWith(height: v)))),
          ],
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(child: IntField(label: 'Border', value: e.borderThickness, min: 1, max: 32000, onChanged: (v) => onChanged(e.copyWith(borderThickness: v)))),
            Expanded(child: IntField(label: 'Rounding 0-8', value: e.cornerRounding, min: 0, max: 8, onChanged: (v) => onChanged(e.copyWith(cornerRounding: v)))),
          ],
        ),
        BoolSwitch(label: 'Reverse print', value: e.reversePrint, onChanged: (v) => onChanged(e.copyWith(reversePrint: v))),
      ],
    );
  }
}

class CircleInspector extends StatelessWidget {
  final CircleElement e;
  final ValueChanged<CircleElement> onChanged;
  const CircleInspector({super.key, required this.e, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        Expanded(child: IntField(label: 'Diameter', value: e.diameter, min: 3, max: 4095, onChanged: (v) => onChanged(e.copyWith(diameter: v)))),
        Expanded(child: IntField(label: 'Border', value: e.borderThickness, min: 1, max: 4095, onChanged: (v) => onChanged(e.copyWith(borderThickness: v)))),
      ],
    );
  }
}

class LineInspector extends StatelessWidget {
  final LineElement e;
  final ValueChanged<LineElement> onChanged;
  const LineInspector({super.key, required this.e, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(child: IntField(label: 'Length', value: e.length, min: 1, max: 32000, onChanged: (v) => onChanged(e.copyWith(length: v)))),
            Expanded(child: IntField(label: 'Thickness', value: e.thickness, min: 1, max: 32000, onChanged: (v) => onChanged(e.copyWith(thickness: v)))),
          ],
        ),
        BoolSwitch(label: 'Vertical', value: e.vertical, onChanged: (v) => onChanged(e.copyWith(vertical: v))),
      ],
    );
  }
}

class ImageInspector extends StatelessWidget {
  final ImageElement e;
  final ValueChanged<ImageElement> onChanged;
  const ImageInspector({super.key, required this.e, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          spacing: 8,
          children: [
            Expanded(child: IntField(label: 'Width', value: e.targetWidth, min: 1, max: 32000, onChanged: (v) => onChanged(e.copyWith(targetWidth: v)))),
            Expanded(child: IntField(label: 'Height', value: e.targetHeight, min: 1, max: 32000, onChanged: (v) => onChanged(e.copyWith(targetHeight: v)))),
          ],
        ),
        BoolSwitch(label: 'Keep aspect', value: e.maintainAspect, onChanged: (v) => onChanged(e.copyWith(maintainAspect: v))),
        EnumDropdown<ZplDitheringAlgorithm>(label: 'Dithering', value: e.ditheringAlgorithm, values: ZplDitheringAlgorithm.values, onChanged: (v) => onChanged(e.copyWith(ditheringAlgorithm: v))),
        Text('${e.image.length} bytes', style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
