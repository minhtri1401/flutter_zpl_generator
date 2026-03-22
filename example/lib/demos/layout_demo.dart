import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

import 'demo_scaffold.dart';

class LayoutDemo extends StatelessWidget {
  const LayoutDemo({super.key});

  static const _config = ZplConfiguration(
    printWidth: 812,
    labelLength: 1400,
    printDensity: ZplPrintDensity.d8,
  );

  @override
  Widget build(BuildContext context) {
    final generator = ZplGenerator(
      config: _config,
      commands: _buildCommands(),
    );

    return DemoScaffold(
      title: 'Layout Containers',
      generator: generator,
      features: const [
        'ZplColumn - vertical stacking with spacing',
        'ZplGridRow + ZplGridCol - 12-unit proportional grid',
        'ZplGridCol offset - column offsetting',
        'ZplTable - headers, rows, column widths',
        'ZplTable borderThickness / cellPadding',
        'ZplTableHeader alignment - per-column alignment',
        'Nested layouts - GridRow inside Column context',
      ],
    );
  }

  List<ZplCommand> _buildCommands() {
    return [
      // Title
      ZplText(
        x: 0, y: 20,
        text: 'LAYOUT CONTAINERS',
        fontHeight: 40, fontWidth: 36,
        alignment: ZplAlignment.center,
      ),
      ZplSeparator(y: 75, thickness: 2),

      // === ZplColumn ===
      ZplText(x: 20, y: 100, text: 'ZplColumn (vertical stack):', fontHeight: 20, fontWidth: 16),
      ZplColumn(
        x: 20, y: 130,
        spacing: 5,
        children: [
          ZplText(text: 'Line 1 - auto Y', fontHeight: 20, fontWidth: 16),
          ZplText(text: 'Line 2 - auto Y', fontHeight: 20, fontWidth: 16),
          ZplText(text: 'Line 3 - auto Y', fontHeight: 20, fontWidth: 16),
          ZplSeparator(thickness: 1),
          ZplText(text: 'After separator', fontHeight: 20, fontWidth: 16),
        ],
      ),

      ZplSeparator(y: 300, thickness: 2),

      // === ZplGridRow - 2 columns (6+6) ===
      ZplText(
        x: 20, y: 325,
        text: 'ZplGridRow - 2 columns (6 + 6):',
        fontHeight: 20, fontWidth: 16,
      ),
      ZplGridRow(
        y: 355,
        children: [
          ZplGridCol(
            width: 6,
            child: ZplColumn(
              children: [
                ZplText(text: 'LEFT COLUMN', fontHeight: 22, fontWidth: 18),
                ZplText(text: 'Width: 6/12 = 50%', fontHeight: 18, fontWidth: 14),
                ZplText(text: 'Auto-positioned', fontHeight: 18, fontWidth: 14),
              ],
            ),
          ),
          ZplGridCol(
            width: 6,
            child: ZplColumn(
              children: [
                ZplText(text: 'RIGHT COLUMN', fontHeight: 22, fontWidth: 18),
                ZplText(text: 'Width: 6/12 = 50%', fontHeight: 18, fontWidth: 14),
                ZplText(text: 'Auto-positioned', fontHeight: 18, fontWidth: 14),
              ],
            ),
          ),
        ],
      ),

      ZplSeparator(y: 480, thickness: 1),

      // === ZplGridRow - 3 columns (4+4+4) ===
      ZplText(
        x: 20, y: 505,
        text: 'ZplGridRow - 3 columns (4 + 4 + 4):',
        fontHeight: 20, fontWidth: 16,
      ),
      ZplGridRow(
        y: 535,
        children: [
          ZplGridCol(
            width: 4,
            child: ZplColumn(
              children: [
                ZplText(text: 'Col A', fontHeight: 22, fontWidth: 18),
                ZplText(text: '33% width', fontHeight: 16, fontWidth: 14),
              ],
            ),
          ),
          ZplGridCol(
            width: 4,
            child: ZplColumn(
              children: [
                ZplText(text: 'Col B', fontHeight: 22, fontWidth: 18),
                ZplText(text: '33% width', fontHeight: 16, fontWidth: 14),
              ],
            ),
          ),
          ZplGridCol(
            width: 4,
            child: ZplColumn(
              children: [
                ZplText(text: 'Col C', fontHeight: 22, fontWidth: 18),
                ZplText(text: '33% width', fontHeight: 16, fontWidth: 14),
              ],
            ),
          ),
        ],
      ),

      ZplSeparator(y: 620, thickness: 1),

      // === ZplGridRow with offset ===
      ZplText(
        x: 20, y: 645,
        text: 'ZplGridCol with offset:',
        fontHeight: 20, fontWidth: 16,
      ),
      ZplGridRow(
        y: 675,
        children: [
          ZplGridCol(
            width: 4,
            offset: 2,
            child: ZplText(text: 'Offset=2', fontHeight: 20, fontWidth: 16),
          ),
          ZplGridCol(
            width: 4,
            child: ZplText(text: 'No offset', fontHeight: 20, fontWidth: 16),
          ),
        ],
      ),

      ZplSeparator(y: 720, thickness: 2),

      // === ZplTable ===
      ZplText(
        x: 20, y: 745,
        text: 'ZplTable (with borders):',
        fontHeight: 20, fontWidth: 16,
      ),
      ZplTable(
        y: 780,
        columnWidths: [5, 2, 2, 3],
        borderThickness: 2,
        cellPadding: 6,
        headers: [
          ZplTableHeader('Product', alignment: ZplAlignment.left,
              fontHeight: 20, fontWidth: 18),
          ZplTableHeader('Qty', alignment: ZplAlignment.center,
              fontHeight: 20, fontWidth: 18),
          ZplTableHeader('Price', alignment: ZplAlignment.right,
              fontHeight: 20, fontWidth: 18),
          ZplTableHeader('Total', alignment: ZplAlignment.right,
              fontHeight: 20, fontWidth: 18),
        ],
        data: [
          ['Widget Pro', '2', '\$15.00', '\$30.00'],
          ['Gadget XL', '1', '\$42.50', '\$42.50'],
          ['Cable USB-C', '5', '\$3.99', '\$19.95'],
        ],
        dataFontHeight: 18,
        dataFontWidth: 16,
      ),

      // Borderless table
      ZplText(
        x: 20, y: 1050,
        text: 'ZplTable (borderless):',
        fontHeight: 20, fontWidth: 16,
      ),
      ZplTable(
        y: 1085,
        columnWidths: [6, 6],
        borderThickness: 0,
        cellPadding: 4,
        headers: [
          ZplTableHeader('Key', fontHeight: 20, fontWidth: 18),
          ZplTableHeader('Value', fontHeight: 20, fontWidth: 18),
        ],
        data: [
          ['Model', 'ZPL-2000'],
          ['Serial', 'SN-9876543'],
          ['Firmware', 'v2.0.0'],
        ],
        dataFontHeight: 18,
        dataFontWidth: 16,
      ),
    ];
  }
}
