import 'barcode_element.dart';
import 'box_element.dart';
import 'circle_element.dart';
import 'image_element.dart';
import 'label_element.dart';
import 'line_element.dart';
import 'text_element.dart';

/// Serialises [LabelElement]s with a `type` discriminator.
class ElementJsonCodec {
  const ElementJsonCodec._();

  static Map<String, dynamic> encode(LabelElement element) => {
        'type': element.typeName,
        'id': element.id,
        ...element.toJson(),
      };

  /// Returns null for unknown types so a document with one bad element
  /// still loads.
  static LabelElement? decode(Map<String, dynamic> json) {
    final type = json['type'];
    final id = stringFromJson(json['id']) ?? ElementId.next(type.toString());
    return switch (type) {
      'text' => TextElement.fromJson(id, json),
      'barcode' => BarcodeElement.fromJson(id, json),
      'box' => BoxElement.fromJson(id, json),
      'circle' => CircleElement.fromJson(id, json),
      'line' => LineElement.fromJson(id, json),
      'image' => ImageElement.fromJson(id, json),
      _ => null,
    };
  }
}
