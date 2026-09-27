import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import '../model/barcode_element.dart';
import '../model/text_element.dart';
import 'inspector_fields.dart';

/// Property fields for [TextElement].
class TextInspector extends StatelessWidget {
  final TextElement e;
  final ValueChanged<TextElement> onChanged;

  const TextInspector({super.key, required this.e, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        StringField(label: 'Text', value: e.text, maxLines: 3, onChanged: (v) => onChanged(e.copyWith(text: v))),
        EnumDropdown<ZplFont>(label: 'Font', value: e.font, values: ZplFont.values, onChanged: (v) => onChanged(e.copyWith(font: v))),
        Row(
          spacing: 8,
          children: [
            Expanded(child: IntField(label: 'Font height', value: e.fontHeight, min: 10, max: 1000, onChanged: (v) => onChanged(e.copyWith(fontHeight: v)))),
            Expanded(child: IntField(label: 'Font width', value: e.fontWidth, min: 10, max: 1000, onChanged: (v) => onChanged(e.copyWith(fontWidth: v)))),
          ],
        ),
        EnumDropdown<ZplOrientation>(label: 'Orientation', value: e.orientation, values: ZplOrientation.values, onChanged: (v) => onChanged(e.copyWith(orientation: v))),
        EnumDropdown<ZplAlignment>(label: 'Alignment', value: e.alignment, values: ZplAlignment.values, nullable: true, onChanged: (v) => onChanged(e.copyWith(alignment: () => v))),
        Row(
          spacing: 8,
          children: [
            Expanded(child: IntField(label: 'Max lines', value: e.maxLines, min: 1, max: 99, onChanged: (v) => onChanged(e.copyWith(maxLines: v)))),
            Expanded(child: IntField(label: 'Line spacing', value: e.lineSpacing, min: 0, max: 500, onChanged: (v) => onChanged(e.copyWith(lineSpacing: v)))),
          ],
        ),
        IntField(label: 'Wrap width (0 = none)', value: e.maxWidth ?? 0, min: 0, onChanged: (v) => onChanged(e.copyWith(maxWidth: () => v == 0 ? null : v))),
        BoolSwitch(label: 'Reverse print', value: e.reversePrint, onChanged: (v) => onChanged(e.copyWith(reversePrint: v))),
      ],
    );
  }
}

/// Property fields for [BarcodeElement].
class BarcodeInspector extends StatelessWidget {
  final BarcodeElement e;
  final ValueChanged<BarcodeElement> onChanged;

  const BarcodeInspector({super.key, required this.e, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        StringField(label: 'Data', value: e.data, onChanged: (v) => onChanged(e.copyWith(data: v))),
        EnumDropdown<ZplBarcodeType>(label: 'Symbology', value: e.type, values: ZplBarcodeType.values, onChanged: (v) => onChanged(e.copyWith(type: v))),
        EnumDropdown<ZplOrientation>(label: 'Orientation', value: e.orientation, values: ZplOrientation.values, onChanged: (v) => onChanged(e.copyWith(orientation: v))),
        if (e.isTwoDimensional) ...[
          IntField(label: 'Magnification', value: e.magnification, min: 1, max: 10, onChanged: (v) => onChanged(e.copyWith(magnification: v))),
          if (e.type == ZplBarcodeType.qrCode)
            EnumDropdown<ZplQrErrorCorrection>(label: 'QR error correction', value: e.qrErrorCorrection, values: ZplQrErrorCorrection.values, onChanged: (v) => onChanged(e.copyWith(qrErrorCorrection: v))),
        ] else ...[
          Row(
            spacing: 8,
            children: [
              Expanded(child: IntField(label: 'Height', value: e.height, min: 1, max: 32000, onChanged: (v) => onChanged(e.copyWith(height: v)))),
              Expanded(child: IntField(label: 'Module width', value: e.moduleWidth, min: 1, max: 10, onChanged: (v) => onChanged(e.copyWith(moduleWidth: v)))),
            ],
          ),
          BoolSwitch(label: 'Interpretation line', value: e.printInterpretationLine, onChanged: (v) => onChanged(e.copyWith(printInterpretationLine: v))),
          BoolSwitch(label: 'Line above', value: e.printInterpretationLineAbove, onChanged: (v) => onChanged(e.copyWith(printInterpretationLineAbove: v))),
        ],
      ],
    );
  }
}
