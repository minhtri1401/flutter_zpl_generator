import 'zpl_command_base.dart';
import 'zpl_configuration.dart';

/// A wrapper command that conditionally includes or excludes its child command.
/// If [condition] is false, this command outputs nothing and takes up zero space
/// in layout containers like [ZplColumn] or [ZplGridRow].
class ZplConditional extends ZplCommand {
  /// The condition determining if the child should be rendered.
  final bool condition;

  /// The child command to render if the condition is true.
  final ZplCommand child;

  const ZplConditional({required this.condition, required this.child});

  @override
  String toZpl(ZplConfiguration context) {
    return condition ? child.toZpl(context) : '';
  }

  @override
  int calculateWidth(ZplConfiguration config) {
    return condition ? child.calculateWidth(config) : 0;
  }
}
