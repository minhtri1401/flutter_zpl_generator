import 'barcode_element.dart';
import 'label_document.dart';
import 'text_element.dart';

/// Placeholder scanning. The syntax is the package's own template
/// convention: `{{name}}` with no spaces, letters/digits/underscore only.
class LabelVariables {
  static final RegExp pattern = RegExp(r'\{\{(\w+)\}\}');

  const LabelVariables._();

  /// Variable names in first-seen order, without duplicates.
  static List<String> scan(LabelDocument doc) {
    final seen = <String>{};
    final out = <String>[];
    for (final e in doc.elements) {
      final source = switch (e) {
        TextElement() => e.text,
        BarcodeElement() => e.data,
        _ => null,
      };
      if (source == null) continue;
      for (final m in pattern.allMatches(source)) {
        final name = m.group(1)!;
        if (seen.add(name)) out.add(name);
      }
    }
    return out;
  }

  /// Placeholder text to insert from the inspector.
  static String placeholder(String name) => '{{$name}}';
}
