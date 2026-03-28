import 'zpl_command_base.dart';
import 'zpl_text.dart';
import 'zpl_barcode.dart';
import 'zpl_image.dart';
import 'zpl_box.dart';
import 'zpl_separator.dart';
import 'zpl_conditional.dart';
import 'zpl_configuration.dart';
import 'enums.dart';

/// A layout helper to arrange multiple [ZplCommand] objects vertically in a column.
/// Children are positioned automatically based on their calculated heights.
class ZplColumn extends ZplCommand {
  final int x;
  final int y;
  final List<ZplCommand> children;
  final int spacing;
  final ZplAlignment alignment;

  /// Maximum width constraint (set by layout containers like ZplGridRow).
  /// When set, children use this width instead of the full label width.
  final int? maxWidth;

  ZplColumn({
    this.x = 0,
    this.y = 0,
    required this.children,
    this.spacing = 10,
    this.alignment = ZplAlignment.left,
    this.maxWidth,
  }) {
    for (final child in children) {
      if (child is ZplColumn) {
        throw ArgumentError(
          'ZplColumn cannot contain another ZplColumn. Nested columns are not supported.',
        );
      }
    }
  }

  @override
  String toZpl(ZplConfiguration context) {
    final sb = StringBuffer();
    var currentY = y;

    for (final child in children) {
      final updatedChild = _updateChildPosition(child, x, currentY, context);
      sb.write(updatedChild.toZpl(context));

      final elementHeight = _calculateElementHeight(child, context);
      currentY += elementHeight + spacing;
    }

    return sb.toString();
  }

  /// Calculate estimated height of an element.
  int _calculateElementHeight(ZplCommand element, ZplConfiguration context) {
    if (element is ZplText) return element.calculateHeight();
    if (element is ZplBarcode) return element.height;
    if (element is ZplBox) return element.height;
    if (element is ZplImage) {
      try {
        return element.height;
      } catch (e) {
        return 60;
      }
    }
    if (element is ZplSeparator) return element.calculateHeight(context);
    if (element is ZplConditional) {
      return element.condition
          ? _calculateElementHeight(element.child, context)
          : 0;
    }
    return 20;
  }

  ZplCommand _updateChildPosition(
    ZplCommand child,
    int newX,
    int newY,
    ZplConfiguration context,
  ) {
    final columnWidth = maxWidth ?? context.printWidth ?? 406;

    if (child is ZplText) {
      final childAlignment = child.alignment ?? alignment;
      return ZplText(
        x: newX,
        y: newY,
        text: child.text,
        font: child.font,
        fontAlias: child.fontAlias,
        fontHeight: child.fontHeight,
        fontWidth: child.fontWidth,
        orientation: child.orientation,
        alignment: childAlignment,
        paddingLeft: child.paddingLeft,
        paddingRight: child.paddingRight,
        maxLines: child.maxLines,
        lineSpacing: child.lineSpacing,
        customFont: child.customFont,
        maxWidth: child.maxWidth ?? columnWidth,
        reversePrint: child.reversePrint,
        serialization: child.serialization,
      );
    }
    if (child is ZplBarcode) {
      final childAlignment = child.alignment ?? alignment;
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
        alignment: childAlignment,
        maxWidth: child.maxWidth ?? columnWidth,
      );
    }
    if (child is ZplSeparator) {
      return ZplSeparator(
        x: newX,
        y: newY,
        type: child.type,
        character: child.character,
        thickness: child.thickness,
        orientation: child.orientation,
        paddingLeft: child.paddingLeft,
        paddingRight: child.paddingRight,
        paddingTop: child.paddingTop,
        paddingBottom: child.paddingBottom,
        length: child.length,
        fontHeight: child.fontHeight,
        fontWidth: child.fontWidth,
        maxWidth: child.maxWidth ?? columnWidth,
      );
    }
    if (child is ZplImage) {
      return ZplImage(
        x: newX,
        y: newY,
        image: child.image,
        graphicName: child.graphicName,
        targetWidth: child.targetWidth,
        targetHeight: child.targetHeight,
        maintainAspect: child.maintainAspect,
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
        reversePrint: child.reversePrint,
      );
    }
    if (child is ZplConditional) {
      return ZplConditional(
        condition: child.condition,
        child: _updateChildPosition(child.child, newX, newY, context),
      );
    }
    return child;
  }

  @override
  int calculateWidth(ZplConfiguration config) {
    int maxW = 0;
    for (final child in children) {
      final childWidth = child.calculateWidth(config);
      if (childWidth > maxW) maxW = childWidth;
    }
    return maxW;
  }
}
