import 'zpl_command_base.dart';
import 'zpl_text.dart';
import 'zpl_barcode.dart';
import 'zpl_image.dart';
import 'zpl_box.dart';
import 'enums.dart';

/// A layout helper to arrange multiple [ZplCommand] objects vertically in a column.
/// This class does not generate ZPL itself but modifies its children to align them.
class ZplColumn extends ZplCommand {
  final int x;
  final int y;
  final List<ZplCommand> children;
  final int spacing;
  final ZplAlignment alignment;

  ZplColumn({
    required this.x,
    required this.y,
    required this.children,
    this.spacing = 10,
    this.alignment = ZplAlignment.left,
  });

  @override
  String toZpl() {
    final sb = StringBuffer();
    var currentY = y;

    for (var child in children) {
      // Create a new instance of the child with updated coordinates
      final updatedChild = _updateChildPosition(child, x, currentY);
      sb.write(updatedChild.toZpl());

      // Calculate height based on element type
      final elementHeight = _calculateElementHeight(child);
      currentY += elementHeight + spacing;
    }

    return sb.toString();
  }

  /// Calculate estimated height of an element
  /// Note: This is a rough estimation. For precise positioning,
  /// you would need to measure actual rendered dimensions.
  int _calculateElementHeight(ZplCommand element) {
    if (element is ZplText) {
      return element.fontHeight ?? 12;
    }
    if (element is ZplBarcode) {
      return element.height;
    }
    if (element is ZplBox) {
      return element.height;
    }
    if (element is ZplImage) {
      // Would need to decode image to get actual height
      // For now, return a default estimate
      return 100;
    }
    return 20; // Default fallback
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
