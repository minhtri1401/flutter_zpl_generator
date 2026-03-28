import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';

void main() {
  group('Enterprise RFID Encoding Tests', () {
    final defaultConfig = const ZplConfiguration(
      printWidth: 406,
      labelLength: 203,
      printDensity: ZplPrintDensity.d8,
    );

    test('ZplRfidSetup generates valid ^RS command default', () {
      final setup = ZplRfidSetup();
      final zpl = setup.toZpl(defaultConfig);
      expect(zpl, '^RS8');
      expect(setup.calculateWidth(defaultConfig), 0);
    });

    test('ZplRfidSetup generates valid ^RS command with params', () {
      final setup = ZplRfidSetup(
        tagType: 8,
        readWritePosition: 'P',
        voidPrintLength: 50,
        labelsPerForm: 2,
      );
      final zpl = setup.toZpl(defaultConfig);
      expect(zpl, '^RS8,P,50,2');
    });

    test('ZplRfidWrite generates valid ^RF write hex sequence', () {
      final rf = ZplRfidWrite(
        data: '11112222',
        operation: RfidOperation.write,
        format: RfidDataFormat.hex,
        startingBlock: 3,
        byteCount: 4,
        memoryBank: RfidMemoryBank.epc,
      );
      final zpl = rf.toZpl(defaultConfig);
      expect(zpl, '^RFW,H,3,4,1^FD11112222^FS');
      expect(rf.calculateWidth(defaultConfig), 0);
    });

    test('ZplRfidWrite generates valid ^RF read EPC sequence', () {
      final rf = ZplRfidWrite(
        data: 'field_1',
        operation: RfidOperation.read,
        format: RfidDataFormat.ascii,
        startingBlock: 0,
        memoryBank: RfidMemoryBank.tid,
      );
      final zpl = rf.toZpl(defaultConfig);
      expect(zpl, '^RFR,A,0,,2^FDfield_1^FS');
    });

    test('ZplRfidWrite throws ArgumentError on invalid hex', () {
      expect(() {
        ZplRfidWrite(
          data: 'ZYX123', // Z, Y, X are not hex!
          format: RfidDataFormat.hex,
        ).toZpl(defaultConfig);
      }, throwsA(isA<ArgumentError>()));
    });

    test('ZplRfidSetup with only voidPrintLength (skip readWritePosition)', () {
      final setup = ZplRfidSetup(tagType: 8, voidPrintLength: 100);
      final zpl = setup.toZpl(defaultConfig);
      expect(zpl, '^RS8,,100');
    });

    test('ZplRfidWrite with EPC format mapping', () {
      final rf = ZplRfidWrite(
        data: '3034257BF461AD20',
        format: RfidDataFormat.epc,
        startingBlock: 0,
        memoryBank: RfidMemoryBank.epc,
      );
      expect(rf.toZpl(defaultConfig), '^RFW,E,0,,1^FD3034257BF461AD20^FS');
    });

    test('ZplRfidWrite with writeWithLock operation', () {
      final rf = ZplRfidWrite(
        data: 'AABB',
        operation: RfidOperation.writeWithLock,
        format: RfidDataFormat.hex,
        startingBlock: 2,
        byteCount: 2,
        memoryBank: RfidMemoryBank.user,
      );
      expect(rf.toZpl(defaultConfig), '^RFL,H,2,2,3^FDAABB^FS');
    });

    test('ZplRfidWrite with reserved memory bank', () {
      final rf = ZplRfidWrite(
        data: 'password_data',
        operation: RfidOperation.specifyPassword,
        format: RfidDataFormat.ascii,
        startingBlock: 0,
        memoryBank: RfidMemoryBank.reserved,
      );
      expect(rf.toZpl(defaultConfig), '^RFS,A,0,,0^FDpassword_data^FS');
    });

    test('RFID commands integrate correctly in ZplGenerator', () async {
      final generator = ZplGenerator(
        config: defaultConfig,
        commands: [
          ZplRfidSetup(tagType: 8),
          ZplRfidWrite(
            data: 'DEADBEEF',
            format: RfidDataFormat.hex,
            startingBlock: 3,
            byteCount: 4,
            memoryBank: RfidMemoryBank.epc,
          ),
          ZplText(x: 10, y: 10, text: 'RFID Label'),
        ],
      );

      final zpl = await generator.build();
      expect(zpl, contains('^XA'));
      expect(zpl, contains('^RS8'));
      expect(zpl, contains('^RFW,H,3,4,1^FDDEADBEEF^FS'));
      expect(zpl, contains('^FDRFID Label^FS'));
      expect(zpl, contains('^XZ'));
    });
  });
}
