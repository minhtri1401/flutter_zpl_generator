import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  test('Render SN directly with Labelary', () async {
    final generator = ZplGenerator(
      config: const ZplConfiguration(printWidth: 406, labelLength: 203),
      commands: [
        ZplText(
          x: 10,
          y: 10,
          text: '001',
          serialization: const ZplSerialConfig(increment: 1, leadingZeros: true),
        ),
      ],
    );

    final zpl = await generator.build();
    print('ZPL output: \n$zpl');
  });
}
