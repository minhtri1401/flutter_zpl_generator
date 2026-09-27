import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  const config = ZplConfiguration();

  group('ZPL Hardware Commands', () {
    test('ZplZbiStart without parameters generates ~JI', () {
      final cmd = ZplZbiStart(path: '/app/program.zbi');
      expect(cmd.toZpl(config), equals('~JI/app/program.zbi\n'));
    });

    test(
      'ZplZbiStart with parameters generates ~JI with comma-separated args',
      () {
        final cmd = ZplZbiStart(
          path: '/app/program.zbi',
          parameters: 'arg1,arg2',
        );
        expect(cmd.toZpl(config), equals('~JI/app/program.zbi,arg1,arg2\n'));
      },
    );

    test('ZplZbiStart with empty parameters behaves as no parameters', () {
      final cmd = ZplZbiStart(path: '/app/program.zbi', parameters: '');
      expect(cmd.toZpl(config), equals('~JI/app/program.zbi\n'));
    });

    test('ZplZbiStop generates ~JQ', () {
      final cmd = const ZplZbiStop();
      expect(cmd.toZpl(config), equals('~JQ\n'));
    });

    test('ZplHostQuery generates ~HQ with query group', () {
      final cmd = ZplHostQuery(queryGroup: 'ES');
      expect(cmd.toZpl(config), equals('~HQES\n'));
    });

    test('ZplHostQuery with different group generates correct ~HQ', () {
      final cmd = ZplHostQuery(queryGroup: 'OD');
      expect(cmd.toZpl(config), equals('~HQOD\n'));
    });

    test('ZplEarlyWarning without value generates ^JH', () {
      final cmd = ZplEarlyWarning(setting: 'E');
      expect(cmd.toZpl(config), equals('^JHE\n'));
    });

    test(
      'ZplEarlyWarning with value generates ^JH with comma-separated value',
      () {
        final cmd = ZplEarlyWarning(setting: 'E', value: 'critical');
        expect(cmd.toZpl(config), equals('^JHE,critical\n'));
      },
    );

    test('ZplEarlyWarning with empty value behaves as no value', () {
      final cmd = ZplEarlyWarning(setting: 'E', value: '');
      expect(cmd.toZpl(config), equals('^JHE\n'));
    });

    test('ZplEarlyWarning calculateWidth returns 0', () {
      final cmd = ZplEarlyWarning(setting: 'E');
      expect(cmd.calculateWidth(config), 0);
    });
  });
}
