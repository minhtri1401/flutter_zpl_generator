import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'editor_controller.dart';

/// Keyboard bindings: arrows nudge (shift = 10 dots), Delete/Backspace,
/// Cmd/Ctrl+Z undo, Shift+Cmd/Ctrl+Z or Ctrl+Y redo, Cmd/Ctrl+D duplicate.
class EditorShortcuts extends StatelessWidget {
  final EditorController controller;
  final Widget child;

  const EditorShortcuts({super.key, required this.controller, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => c.nudgeSelected(-1, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => c.nudgeSelected(1, 0),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => c.nudgeSelected(0, -1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => c.nudgeSelected(0, 1),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true): () => c.nudgeSelected(-10, 0),
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true): () => c.nudgeSelected(10, 0),
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): () => c.nudgeSelected(0, -10),
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): () => c.nudgeSelected(0, 10),
        const SingleActivator(LogicalKeyboardKey.delete): c.removeSelected,
        const SingleActivator(LogicalKeyboardKey.backspace): c.removeSelected,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): c.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): c.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): c.redo,
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): c.redo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): c.redo,
        const SingleActivator(LogicalKeyboardKey.keyD, meta: true): c.duplicateSelected,
        const SingleActivator(LogicalKeyboardKey.keyD, control: true): c.duplicateSelected,
      },
      child: child,
    );
  }
}
