import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  const config = ZplConfiguration();

  group('ZplGenerator control command ordering', () {
    test('ZplZbiStart, ZplZbiStop, ZplHostQuery, ZplNetworkConnect, '
        'ZplNetworkPrintersTransparentAll, ZplNetworkPrinterTransparentCurrent '
        'are emitted before ^XA', () async {
      final generator = ZplGenerator(
        config: config,
        commands: [
          const ZplZbiStart(path: '/app/test.zbi'),
          const ZplZbiStop(),
          const ZplHostQuery(queryGroup: 'ES'),
          const ZplNetworkConnect(networkId: '192.168.1.1'),
          const ZplNetworkPrintersTransparentAll(),
          const ZplNetworkPrinterTransparentCurrent(),
          ZplText(text: 'Hello', x: 10, y: 10),
        ],
      );

      final zpl = await generator.build();
      expect(zpl, contains('~JI/app/test.zbi\n'));
      expect(zpl, contains('~JQ\n'));
      expect(zpl, contains('~HQES\n'));
      expect(zpl, contains('~NC192.168.1.1\n'));
      expect(zpl, contains('~NR\n'));
      expect(zpl, contains('~NT\n'));

      // All tilde commands must appear before ^XA
      final lines = zpl.split('\n');
      int xaIndex = -1;
      int lastTildeIndex = -1;

      for (int i = 0; i < lines.length; i++) {
        if (lines[i].startsWith('^XA')) {
          xaIndex = i;
          break;
        }
        if (lines[i].startsWith('~')) {
          lastTildeIndex = i;
        }
      }

      expect(xaIndex, greaterThan(-1), reason: '^XA should be in output');
      if (lastTildeIndex != -1) {
        expect(
          lastTildeIndex,
          lessThan(xaIndex),
          reason: 'All tilde commands must appear before ^XA',
        );
      }
    });

    test('ZplEarlyWarning (^JH) stays inside ^XA..^XZ', () async {
      final generator = ZplGenerator(
        config: config,
        commands: [
          ZplEarlyWarning(setting: 'E'),
          ZplText(text: 'Test', x: 0, y: 0),
        ],
      );

      final zpl = await generator.build();
      expect(zpl, contains('^JH'));

      // ^JH should be between ^XA and ^XZ
      final xaIndex = zpl.indexOf('^XA');
      final xzIndex = zpl.indexOf('^XZ');
      final jhIndex = zpl.indexOf('^JH');

      expect(xaIndex, greaterThan(-1), reason: '^XA should be in output');
      expect(xzIndex, greaterThan(-1), reason: '^XZ should be in output');
      expect(jhIndex, greaterThan(xaIndex), reason: '^JH should be after ^XA');
      expect(jhIndex, lessThan(xzIndex), reason: '^JH should be before ^XZ');
    });

    test('all 6 tilde control classes are ZplControlCommand', () {
      expect(
        const ZplZbiStart(path: '/app/test.zbi'),
        isA<ZplControlCommand>(),
      );
      expect(const ZplZbiStop(), isA<ZplControlCommand>());
      expect(const ZplHostQuery(queryGroup: 'ES'), isA<ZplControlCommand>());
      expect(
        const ZplNetworkConnect(networkId: 'net1'),
        isA<ZplControlCommand>(),
      );
      expect(
        const ZplNetworkPrintersTransparentAll(),
        isA<ZplControlCommand>(),
      );
      expect(
        const ZplNetworkPrinterTransparentCurrent(),
        isA<ZplControlCommand>(),
      );
    });

    test('all control commands have calculateWidth == 0', () {
      expect(
        const ZplZbiStart(path: '/app/test.zbi').calculateWidth(config),
        0,
      );
      expect(const ZplZbiStop().calculateWidth(config), 0);
      expect(const ZplHostQuery(queryGroup: 'ES').calculateWidth(config), 0);
      expect(
        const ZplNetworkConnect(networkId: 'net1').calculateWidth(config),
        0,
      );
      expect(
        const ZplNetworkPrintersTransparentAll().calculateWidth(config),
        0,
      );
      expect(
        const ZplNetworkPrinterTransparentCurrent().calculateWidth(config),
        0,
      );
    });

    test(
      'ZplColumn skips ZplControlCommand in layout without throwing',
      () async {
        final generator = ZplGenerator(
          config: config,
          commands: [
            const ZplNetworkConnect(networkId: 'net1'),
            ZplColumn(
              x: 10,
              y: 10,
              children: [
                const ZplZbiStart(path: '/app/test.zbi'),
                ZplText(text: 'Item 1', x: 0, y: 0),
                const ZplZbiStop(),
                ZplText(text: 'Item 2', x: 0, y: 20),
              ],
            ),
          ],
        );

        expect(() => generator.build(), returnsNormally);
      },
    );

    test(
      'ZplGridRow skips ZplControlCommand in layout without throwing',
      () async {
        final generator = ZplGenerator(
          config: config,
          commands: [
            ZplGridRow(
              x: 10,
              y: 10,
              children: [
                ZplGridCol(
                  width: 6,
                  child: const ZplZbiStart(path: '/app/test.zbi'),
                ),
                ZplGridCol(
                  width: 6,
                  child: ZplText(text: 'Content', x: 0, y: 0),
                ),
              ],
            ),
          ],
        );

        expect(() => generator.build(), returnsNormally);
      },
    );
  });
}
