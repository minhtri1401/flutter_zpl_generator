import 'zpl_command_base.dart';
import 'zpl_text.dart';
import 'zpl_barcode.dart';
import 'zpl_image.dart';
import 'zpl_box.dart';
import 'enums.dart';

/// A layout helper to arrange multiple [ZplCommand] objects horizontally in a row.
/// This class does not generate ZPL itself but modifies its children to align them.
class ZplRow extends ZplCommand {
  final int x;
  final int y;
  final List<ZplCommand> children;
  final int spacing;
  final ZplAlignment alignment;

  ZplRow({
    required this.x,
    required this.y,
    required this.children,
    this.spacing = 10,
    this.alignment = ZplAlignment.left,
  });

  @override
  String toZpl() {
    final sb = StringBuffer();
    var currentX = x;

    for (var child in children) {
      // Create a new instance of the child with updated coordinates
      final updatedChild = _updateChildPosition(child, currentX, y);
      sb.write(updatedChild.toZpl());

      // Calculate width based on element type
      final elementWidth = _calculateElementWidth(child);
      currentX += elementWidth + spacing;
    }

    return sb.toString();
  }

  /// Calculate estimated width of an element
  /// Note: This is a rough estimation. For precise positioning,
  /// you would need to measure actual rendered dimensions.
  int _calculateElementWidth(ZplCommand element) {
    if (element is ZplText) {
      // Rough estimate: 8 dots per character for average fonts
      final charWidth = element.fontWidth ?? 8;
      return element.text.length * charWidth;
    }
    if (element is ZplBarcode) {
      // Code 128: approximately 11 * number of characters
      return element.data.length * 11;
    }
    if (element is ZplBox) {
      return element.width;
    }
    if (element is ZplImage) {
      // Would need to decode image to get actual width
      // For now, return a default estimate
      return 100;
    }
    return 50; // Default fallback
  }

  ZplCommand _updateChildPosition(ZplCommand child, int newX, int newY) {
    if (child is ZplText) {
      return ZplText(
        x: newX,
        y: newY,
        text: child.text,
        font: child.font,
        fontHeight: child.fontHeight,
        fontWidth: child.fontWidth,
        orientation: child.orientation,
      );
    }
    if (child is ZplBarcode) {
      return ZplBarcode(
        x: newX,
        y: newY,
        data: child.data,
        type: child.type,
        height: child.height,
        orientation: child.orientation,
        printInterpretationLine: child.printInterpretationLine,
        printInterpretationLineAbove: child.printInterpretationLineAbove,
        moduleWidth: child.moduleWidth,
        wideBarToNarrowBarRatio: child.wideBarToNarrowBarRatio,
      );
    }
    if (child is ZplImage) {
      return ZplImage(
        x: newX,
        y: newY,
        image: child.image,
        graphicName: child.graphicName,
      );
    }
    if (child is ZplBox) {
      return ZplBox(
        x: newX,
        y: newY,
        width: child.width,
        height: child.height,
        borderThickness: child.borderThickness,
        cornerRounding: child.cornerRounding,
      );
    }
    return child; // Return unchanged if type is not recognized
  }
}
