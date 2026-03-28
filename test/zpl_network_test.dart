import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:flutter_zpl_generator/src/zpl_configuration.dart';

void main() {
  const config = ZplConfiguration();

  group('ZPL Network Commands', () {
    test('ZplNetworkBoot generates ^NB', () {
      final cmd = ZplNetworkBoot(check: 15);
      expect(cmd.toZpl(config), equals('^NB15\n'));
    });

    test('ZplNetworkDevice generates ^NC', () {
      final cmd = ZplNetworkDevice(device: 1);
      expect(cmd.toZpl(config), equals('^NC1\n'));
    });

    test('ZplNetworkConnect generates ~NC', () {
      final cmd = ZplNetworkConnect(networkId: '192.168.1.10');
      expect(cmd.toZpl(config), equals('~NC192.168.1.10\n'));
    });

    test('ZplNetworkSettings generates ^ND', () {
      final cmd = ZplNetworkSettings(
        device: 1,
        ip: '10.0.0.1',
        timeout: 50,
        arp: 'Y',
      );
      expect(cmd.toZpl(config), equals('^ND1,,10.0.0.1,,,,50,,Y,\n'));
    });

    test('ZplNetworkId generates ^NI', () {
      final cmd = ZplNetworkId(networkId: '1');
      expect(cmd.toZpl(config), equals('^NI1\n'));
    });

    test('ZplNetworkSnmp generates ^NN', () {
      final cmd = ZplNetworkSnmp(
        name: 'MyPrinter',
        location: 'Office',
        getCommunity: 'public',
      );
      expect(cmd.toZpl(config), equals('^NNMyPrinter,,Office,public,,\n'));
    });

    test('ZplNetworkPrimaryDevice generates ^NP', () {
      final cmd = ZplNetworkPrimaryDevice(device: 2);
      expect(cmd.toZpl(config), equals('^NP2\n'));
    });

    test('ZplNetworkPrintersTransparentAll generates ~NR', () {
      final cmd = const ZplNetworkPrintersTransparentAll();
      expect(cmd.toZpl(config), equals('~NR\n'));
    });

    test('ZplNetworkWiredSettings generates ^NS', () {
      final cmd = ZplNetworkWiredSettings(
        res: 'A',
        ip: '192.168.1.50',
        mask: '255.255.255.0',
        port: 9100,
      );
      expect(cmd.toZpl(config),
          equals('^NSA,192.168.1.50,255.255.255.0,,,,,,9100\n'));
    });

    test('ZplNetworkPrinterTransparentCurrent generates ~NT', () {
      final cmd = const ZplNetworkPrinterTransparentCurrent();
      expect(cmd.toZpl(config), equals('~NT\n'));
    });

    test('ZplNetworkSmtp generates ^NT', () {
      final cmd = ZplNetworkSmtp(server: 'smtp.gmail.com', domain: 'gmail.com');
      // Because we used ^NT, let's make sure it returns exactly ^NT.
      expect(cmd.toZpl(config), equals('^NTsmtp.gmail.com,gmail.com\n'));
    });

    test('ZplNetworkPasswordTimeout generates ^NW', () {
      final cmd = ZplNetworkPasswordTimeout(timeout: 300);
      expect(cmd.toZpl(config), equals('^NW300\n'));
    });
  });
}
