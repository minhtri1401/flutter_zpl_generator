import 'zpl_command_base.dart';

/// Represents a column in a 12-unit grid system.
///
/// This class defines a single column within a [ZplGridRow], specifying
/// how many grid units (1-12) it should occupy and what content it contains.
class ZplGridCol {
  /// The child ZPL command to be rendered in this column.
  final ZplCommand child;

  /// The width of the column in grid units (1-12).
  ///
  /// - 1 = 1/12 of total width (~8.33%)
  /// - 2 = 2/12 of total width (~16.67%)
  /// - 3 = 3/12 of total width (25%)
  /// - 6 = 6/12 of total width (50%)
  /// - 12 = 12/12 of total width (100%)
  final int width;

  /// Optional offset from the left in grid units.
  ///
  /// This creates empty space before the column content starts.
  /// Useful for creating gaps or aligning content.
  final int offset;

  ZplGridCol({required this.child, required this.width, this.offset = 0})
    : assert(width >= 1 && width <= 12, 'Width must be between 1 and 12'),
      assert(offset >= 0 && offset <= 11, 'Offset must be between 0 and 11'),
      assert(width + offset <= 12, 'Width + offset cannot exceed 12');
}
