import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

class _FakeControl extends ZplControlCommand {
  const _FakeControl();
  @override
  String toZpl(ZplConfiguration context) => '~FAKE\n';
}

class _FakeFormat extends ZplCommand {
  const _FakeFormat();
  @override
  String toZpl(ZplConfiguration context) => '^FAKE\n';
  @override
  int calculateWidth(ZplConfiguration config) => 10;
}

void main() {
  group('ZplControlCommand', () {
    test('is a subtype of ZplCommand', () {
      const c = _FakeControl();
      expect(c, isA<ZplCommand>());
      expect(c, isA<ZplControlCommand>());
    });

    test('format commands are not ZplControlCommand', () {
      const f = _FakeFormat();
      expect(f, isA<ZplCommand>());
      expect(f, isNot(isA<ZplControlCommand>()));
    });

    test('default calculateWidth returns 0', () {
      const c = _FakeControl();
      expect(c.calculateWidth(const ZplConfiguration()), 0);
    });

    test('toZpl returns subclass-provided string', () {
      const c = _FakeControl();
      expect(c.toZpl(const ZplConfiguration()), '~FAKE\n');
    });
  });
}
