import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'demo_scaffold.dart';

class GraphicsDemo extends StatelessWidget {
  const GraphicsDemo({super.key});

  static const _config = ZplConfiguration(
    printWidth: 812,
    labelLength: 1100,
    printDensity: ZplPrintDensity.d8,
  );

  @override
  Widget build(BuildContext context) {
    final generator = ZplGenerator(config: _config, commands: _buildCommands());

    return DemoScaffold(
      title: 'Graphics & Shapes',
      generator: generator,
      features: const [
        'ZplBox - rectangle with border (^GB)',
        'ZplBox cornerRounding - rounded corners (0-8)',
        'ZplBox reversePrint - inverted box (^FR)',
        'ZplGraphicCircle - circle shape (^GC)',
        'ZplGraphicEllipse - ellipse shape (^GE)',
        'ZplGraphicDiagonalLine - diagonal line (^GD)',
        'ZplGraphicDiagonalLine orientation - R/L leaning',
        'ZplRaw - escape hatch for arbitrary ZPL',
        'ZplSeparator - box and character types',
      ],
    );
  }

  List<ZplCommand> _buildCommands() {
    return [
      // Title
      ZplText(
        x: 0,
        y: 20,
        text: 'GRAPHICS & SHAPES',
        fontHeight: 40,
        fontWidth: 36,
        alignment: ZplAlignment.center,
      ),
      ZplSeparator(y: 75, thickness: 2),

      // === Boxes ===
      ZplText(x: 20, y: 100, text: 'Boxes:', fontHeight: 20, fontWidth: 16),

      // Simple box
      ZplBox(x: 20, y: 130, width: 150, height: 100, borderThickness: 2),
      ZplText(x: 35, y: 165, text: 'Border', fontHeight: 16, fontWidth: 14),

      // Rounded box
      ZplBox(
        x: 200,
        y: 130,
        width: 150,
        height: 100,
        borderThickness: 2,
        cornerRounding: 5,
      ),
      ZplText(x: 215, y: 165, text: 'Rounded', fontHeight: 16, fontWidth: 14),

      // Filled box
      ZplBox(x: 380, y: 130, width: 150, height: 100, borderThickness: 100),
      ZplText(
        x: 395,
        y: 165,
        text: 'Filled',
        fontHeight: 16,
        fontWidth: 14,
        reversePrint: true,
      ),

      // Reverse print box
      ZplBox(
        x: 560,
        y: 130,
        width: 150,
        height: 100,
        borderThickness: 100,
        reversePrint: true,
      ),
      ZplText(x: 575, y: 165, text: 'Reverse', fontHeight: 16, fontWidth: 14),

      ZplSeparator(y: 255, thickness: 1),

      // === Circles ===
      ZplText(
        x: 20,
        y: 275,
        text: 'Circles (^GC):',
        fontHeight: 20,
        fontWidth: 16,
      ),

      // Thin circle
      ZplGraphicCircle(x: 20, y: 310, diameter: 100, borderThickness: 2),
      ZplText(x: 45, y: 350, text: 'Thin', fontHeight: 14, fontWidth: 12),

      // Thick circle
      ZplGraphicCircle(x: 160, y: 310, diameter: 100, borderThickness: 8),
      ZplText(x: 180, y: 350, text: 'Thick', fontHeight: 14, fontWidth: 12),

      // Filled circle
      ZplGraphicCircle(x: 300, y: 310, diameter: 100, borderThickness: 50),
      ZplText(
        x: 320,
        y: 350,
        text: 'Fill',
        fontHeight: 14,
        fontWidth: 12,
        reversePrint: true,
      ),

      // Small circle
      ZplGraphicCircle(x: 440, y: 335, diameter: 50, borderThickness: 2),

      ZplSeparator(y: 430, thickness: 1),

      // === Ellipses ===
      ZplText(
        x: 20,
        y: 450,
        text: 'Ellipses (^GE):',
        fontHeight: 20,
        fontWidth: 16,
      ),

      // Wide ellipse
      ZplGraphicEllipse(
        x: 20,
        y: 485,
        width: 200,
        height: 80,
        borderThickness: 2,
      ),
      ZplText(x: 70, y: 515, text: 'Wide', fontHeight: 14, fontWidth: 12),

      // Tall ellipse
      ZplGraphicEllipse(
        x: 260,
        y: 485,
        width: 80,
        height: 100,
        borderThickness: 2,
      ),
      ZplText(x: 275, y: 525, text: 'Tall', fontHeight: 14, fontWidth: 12),

      // Thick ellipse
      ZplGraphicEllipse(
        x: 380,
        y: 485,
        width: 180,
        height: 90,
        borderThickness: 8,
      ),
      ZplText(x: 430, y: 520, text: 'Thick', fontHeight: 14, fontWidth: 12),

      ZplSeparator(y: 610, thickness: 1),

      // === Diagonal Lines ===
      ZplText(
        x: 20,
        y: 630,
        text: 'Diagonal Lines (^GD):',
        fontHeight: 20,
        fontWidth: 16,
      ),

      // Right-leaning
      ZplGraphicDiagonalLine(
        x: 20,
        y: 665,
        width: 150,
        height: 120,
        borderThickness: 3,
        orientation: 'R',
      ),
      ZplText(x: 30, y: 795, text: 'Right (R)', fontHeight: 14, fontWidth: 12),

      // Left-leaning
      ZplGraphicDiagonalLine(
        x: 200,
        y: 665,
        width: 150,
        height: 120,
        borderThickness: 3,
        orientation: 'L',
      ),
      ZplText(x: 215, y: 795, text: 'Left (L)', fontHeight: 14, fontWidth: 12),

      // X pattern using both
      ZplGraphicDiagonalLine(
        x: 420,
        y: 665,
        width: 120,
        height: 120,
        borderThickness: 2,
        orientation: 'R',
      ),
      ZplGraphicDiagonalLine(
        x: 420,
        y: 665,
        width: 120,
        height: 120,
        borderThickness: 2,
        orientation: 'L',
      ),
      ZplText(x: 440, y: 795, text: 'X pattern', fontHeight: 14, fontWidth: 12),

      ZplSeparator(y: 825, thickness: 1),

      // === ZplRaw escape hatch ===
      ZplText(
        x: 20,
        y: 845,
        text: 'ZplRaw (escape hatch):',
        fontHeight: 20,
        fontWidth: 16,
      ),
      // Raw ZPL: draw a custom field with direct ZPL commands
      ZplRaw(command: '^FO20,880^A0N,24,20^FDThis line is from ZplRaw^FS'),
      ZplRaw(command: '^FO20,915^GB772,0,3^FS'),
      ZplText(
        x: 20,
        y: 935,
        text: 'Raw ZPL lets you inject any ^command directly',
        fontHeight: 18,
        fontWidth: 14,
      ),
    ];
  }
}
