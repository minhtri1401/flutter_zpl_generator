import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'demo_scaffold.dart';

class TextDemo extends StatelessWidget {
  const TextDemo({super.key});

  static const _config = ZplConfiguration(
    printWidth: 812,
    labelLength: 1000,
    printDensity: ZplPrintDensity.d8,
  );

  @override
  Widget build(BuildContext context) {
    final generator = ZplGenerator(config: _config, commands: _buildCommands());

    return DemoScaffold(
      title: 'Text & Typography',
      generator: generator,
      features: const [
        'ZplText - basic text rendering',
        'alignment: left, center, right (via ^FB)',
        'fontHeight / fontWidth - scalable bitmap fonts',
        'maxLines + lineSpacing - multi-line text wrapping',
        'reversePrint: true - white on black (^FR)',
        'ZplBox with reversePrint - dark background strip',
        'paddingLeft / paddingRight - horizontal padding',
      ],
    );
  }

  List<ZplCommand> _buildCommands() {
    return [
      // Title
      ZplText(
        x: 0,
        y: 20,
        text: 'TEXT FEATURES',
        fontHeight: 40,
        fontWidth: 36,
        alignment: ZplAlignment.center,
      ),

      // Separator
      ZplSeparator(y: 75, thickness: 2),

      // Left-aligned (default)
      ZplText(
        x: 20,
        y: 100,
        text: 'Left aligned (default)',
        fontHeight: 24,
        fontWidth: 20,
      ),

      // Center-aligned
      ZplText(
        x: 0,
        y: 140,
        text: 'Center aligned',
        fontHeight: 24,
        fontWidth: 20,
        alignment: ZplAlignment.center,
      ),

      // Right-aligned
      ZplText(
        x: 0,
        y: 180,
        text: 'Right aligned',
        fontHeight: 24,
        fontWidth: 20,
        alignment: ZplAlignment.right,
      ),

      // Separator
      ZplSeparator(y: 220, thickness: 1),

      // Font sizes showcase
      ZplText(x: 20, y: 245, text: 'Small font', fontHeight: 18, fontWidth: 14),
      ZplText(
        x: 20,
        y: 275,
        text: 'Medium font',
        fontHeight: 28,
        fontWidth: 24,
      ),
      ZplText(x: 20, y: 315, text: 'Large font', fontHeight: 42, fontWidth: 38),

      // Separator
      ZplSeparator(y: 370, thickness: 1),

      // Multi-line text
      ZplText(
        x: 20,
        y: 395,
        text: 'Multi-line:',
        fontHeight: 22,
        fontWidth: 18,
      ),
      ZplText(
        x: 20,
        y: 430,
        text:
            'This is a longer text that demonstrates multi-line '
            'wrapping with lineSpacing. The text will wrap based on '
            'the available label width and maxLines setting.',
        fontHeight: 20,
        fontWidth: 18,
        maxLines: 4,
        lineSpacing: 4,
      ),

      // Separator
      ZplSeparator(y: 560, thickness: 1),

      // Reverse print (white on black)
      ZplText(
        x: 20,
        y: 585,
        text: 'Reverse print:',
        fontHeight: 22,
        fontWidth: 18,
      ),
      // Black background box
      ZplBox(x: 20, y: 620, width: 772, height: 50, borderThickness: 50),
      // White text on black background
      ZplText(
        x: 20,
        y: 630,
        text: 'WHITE ON BLACK (reversePrint: true)',
        fontHeight: 28,
        fontWidth: 22,
        reversePrint: true,
      ),

      // Padded text
      ZplText(
        x: 0,
        y: 700,
        text: 'Padded text (L:50, R:50)',
        fontHeight: 22,
        fontWidth: 18,
        paddingLeft: 50,
        paddingRight: 50,
        alignment: ZplAlignment.center,
      ),

      // Separator
      ZplSeparator(y: 740, thickness: 1),

      // Character separator demo
      ZplText(
        x: 20,
        y: 765,
        text: 'Character separator:',
        fontHeight: 20,
        fontWidth: 16,
      ),
      ZplSeparator(
        y: 800,
        type: ZplSeparatorType.character,
        character: '*',
        fontHeight: 16,
        fontWidth: 12,
      ),

      // Box separator demo
      ZplText(
        x: 20,
        y: 835,
        text: 'Box separator (thick):',
        fontHeight: 20,
        fontWidth: 16,
      ),
      ZplSeparator(y: 870, thickness: 4),
    ];
  }
}
