// test/labelary_service_test.dart
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'labelary_service_test.mocks.dart';

@GenerateMocks([http.Client, http.StreamedResponse])
void main() {
  group('LabelaryService Tests', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();
    });

    group('renderZpl', () {
      test('renders ZPL to PNG with default parameters', () async {
        // Arrange
        final commands = [
          const ZplConfiguration(
            printWidth: 406,
            labelLength: 609,
            printDensity: ZplPrintDensity.d8,
          ),
          const ZplText(x: 50, y: 50, text: 'Hello World'),
        ];
        final generator = ZplGenerator(commands);
        final zpl = generator.build();
        final expectedUrl = Uri.parse(
          'https://api.labelary.com/v1/printers/8dpmm/labels/4.0x6.0/0/',
        );
        final mockResponse = http.Response.bytes(
          Uint8List.fromList([137, 80, 78, 71]), // PNG header bytes
          200,
        );

        when(
          mockClient.post(
            expectedUrl,
            headers: {'Accept': 'image/png'},
            body: zpl,
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await LabelaryService.renderZplSimple(
          zpl,
          client: mockClient,
        );

        // Assert
        expect(result, equals(Uint8List.fromList([137, 80, 78, 71])));
        verify(
          mockClient.post(
            expectedUrl,
            headers: {'Accept': 'image/png'},
            body: zpl,
          ),
        ).called(1);

        // Verify the generated ZPL contains expected commands
        expect(zpl.contains('^XA'), true);
        expect(zpl.contains('^XZ'), true);
        expect(zpl.contains('^PW406'), true);
        expect(zpl.contains('^LL609'), true);
        expect(zpl.contains('^JMA'), true);
        expect(zpl.contains('^FO50,50'), true);
        expect(zpl.contains('^FDHello World^FS'), true);
      });

      test('renders ZPL to PDF with custom dimensions', () async {
        // Arrange
        final commands = [
          const ZplConfiguration(
            printWidth: 900,
            labelLength: 600,
            printDensity: ZplPrintDensity.d12,
          ),
          const ZplText(x: 100, y: 100, text: 'Test Label'),
        ];
        final generator = ZplGenerator(commands);
        final zpl = generator.build();

        final expectedUrl = Uri.parse(
          'https://api.labelary.com/v1/printers/12dpmm/labels/3.0x2.0/0/',
        );
        final mockResponse = http.Response.bytes(
          Uint8List.fromList([37, 80, 68, 70]), // PDF header bytes
          200,
        );

        when(
          mockClient.post(
            expectedUrl,
            headers: {'Accept': 'application/pdf'},
            body: zpl,
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await LabelaryService.renderZplSimple(
          zpl,
          density: LabelaryPrintDensity.d12,
          width: 3.0,
          height: 2.0,
          outputFormat: LabelaryOutputFormat.pdf,
          client: mockClient,
        );

        // Assert
        expect(result, equals(Uint8List.fromList([37, 80, 68, 70])));
        verify(
          mockClient.post(
            expectedUrl,
            headers: {'Accept': 'application/pdf'},
            body: zpl,
          ),
        ).called(1);

        // Verify the generated ZPL contains expected commands
        expect(zpl.contains('^XA'), true);
        expect(zpl.contains('^XZ'), true);
        expect(zpl.contains('^PW900'), true);
        expect(zpl.contains('^LL600'), true);
        expect(zpl.contains('^JMA'), true);
        expect(zpl.contains('^FO100,100'), true);
        expect(zpl.contains('^FDTest Label^FS'), true);
      });

      test('renders ZPL with specific label index', () async {
        // Arrange - Create multiple labels by generating each separately
        final label1Commands = [
          const ZplConfiguration(
            printWidth: 406,
            labelLength: 609,
            printDensity: ZplPrintDensity.d8,
          ),
          const ZplText(x: 50, y: 50, text: 'Label 1'),
        ];
        final label2Commands = [
          const ZplConfiguration(
            printWidth: 406,
            labelLength: 609,
            printDensity: ZplPrintDensity.d8,
          ),
          const ZplText(x: 50, y: 50, text: 'Label 2'),
        ];

        final generator1 = ZplGenerator(label1Commands);
        final generator2 = ZplGenerator(label2Commands);

        // Concatenate multiple labels into one ZPL script
        final zpl = generator1.build() + generator2.build();

        final expectedUrl = Uri.parse(
          'https://api.labelary.com/v1/printers/8dpmm/labels/4.0x6.0/1/',
        );
        final mockResponse = http.Response.bytes(
          Uint8List.fromList([137, 80, 78, 71]),
          200,
        );

        when(
          mockClient.post(
            expectedUrl,
            headers: {'Accept': 'image/png'},
            body: zpl,
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await LabelaryService.renderZplSimple(
          zpl,
          index: 1,
          client: mockClient,
        );

        // Assert
        expect(result, equals(Uint8List.fromList([137, 80, 78, 71])));
        verify(
          mockClient.post(
            expectedUrl,
            headers: {'Accept': 'image/png'},
            body: zpl,
          ),
        ).called(1);

        // Verify the generated ZPL contains multiple label sequences
        expect(zpl.split('^XA').length - 1, equals(2)); // Two ^XA commands
        expect(zpl.split('^XZ').length - 1, equals(2)); // Two ^XZ commands
        expect(zpl.contains('Label 1'), true);
        expect(zpl.contains('Label 2'), true);
      });

      test('throws exception on HTTP error', () async {
        // Arrange
        const zpl = '^XA^FO50,50^A0N,50,50^FDError Test^FS^XZ';
        final expectedUrl = Uri.parse(
          'https://api.labelary.com/v1/printers/8dpmm/labels/4.0x6.0/0/',
        );
        final mockResponse = http.Response('Bad Request', 400);

        when(
          mockClient.post(
            expectedUrl,
            headers: {'Accept': 'image/png'},
            body: zpl,
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act & Assert
        expect(
          () => LabelaryService.renderZplSimple(zpl, client: mockClient),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to render ZPL. Status: 400'),
            ),
          ),
        );
      });
    });

    group('renderFromGenerator', () {
      test('renders from ZplGenerator with correct URL construction', () async {
        // Arrange
        final commands = [
          const ZplConfiguration(
            printWidth: 406,
            labelLength: 203,
            printDensity: ZplPrintDensity.d8,
          ),
          const ZplText(x: 10, y: 10, text: 'Generator Test'),
        ];
        final generator = ZplGenerator(commands);
        final expectedZpl = generator.build();
        final expectedUrl = Uri.parse(
          'https://api.labelary.com/v1/printers/8dpmm/labels/2.0x1.0/0/',
        );
        final mockResponse = http.Response.bytes(
          Uint8List.fromList([1, 2, 3, 4]),
          200,
        );

        when(
          mockClient.post(
            expectedUrl,
            headers: {'Accept': 'image/png'},
            body: expectedZpl,
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await LabelaryService.renderFromGeneratorSimple(
          generator,
          client: mockClient,
        );

        // Assert
        expect(result, equals(Uint8List.fromList([1, 2, 3, 4])));
        verify(
          mockClient.post(
            expectedUrl,
            headers: {'Accept': 'image/png'},
            body: expectedZpl,
          ),
        ).called(1);
      });

      test('throws exception when ZplConfiguration is missing', () async {
        // Arrange
        final commands = [const ZplText(x: 10, y: 10, text: 'No Config')];
        final generator = ZplGenerator(commands);

        // Act & Assert
        expect(
          () => LabelaryService.renderFromGeneratorSimple(
            generator,
            client: mockClient,
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('ZplConfiguration must be provided'),
            ),
          ),
        );
      });

      test('handles different print densities correctly', () async {
        // Arrange
        final commands = [
          const ZplConfiguration(
            printWidth: 609,
            labelLength: 304,
            printDensity: ZplPrintDensity.d12,
          ),
          const ZplText(x: 20, y: 20, text: 'High Density'),
        ];
        final generator = ZplGenerator(commands);
        final expectedZpl = generator.build();
        final expectedUrl = Uri.parse(
          'https://api.labelary.com/v1/printers/12dpmm/labels/2.03x1.013333/0/',
        );
        final mockResponse = http.Response.bytes(
          Uint8List.fromList([5, 6, 7, 8]),
          200,
        );

        when(
          mockClient.post(
            expectedUrl,
            headers: {'Accept': 'image/png'},
            body: expectedZpl,
          ),
        ).thenAnswer((_) async => mockResponse);

        // Act
        final result = await LabelaryService.renderFromGeneratorSimple(
          generator,
          client: mockClient,
        );

        // Assert
        expect(result, equals(Uint8List.fromList([5, 6, 7, 8])));
      });
    });

    group('convertImageToGraphic', () {
      test('converts image to ZPL graphic successfully', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
        const fileName = 'test.png';
        const expectedZplOutput = '~DGR:TEST.GRF,00040,08,1F1F1F1F1F1F1F1F';

        final mockStreamedResponse = MockStreamedResponse();
        when(mockStreamedResponse.statusCode).thenReturn(200);
        when(mockStreamedResponse.stream).thenAnswer(
          (_) => http.ByteStream.fromBytes(expectedZplOutput.codeUnits),
        );

        when(
          mockClient.send(any),
        ).thenAnswer((_) async => mockStreamedResponse);

        // Act
        final result = await LabelaryService.convertImageToGraphic(
          imageData,
          fileName,
        );

        // Assert
        expect(result, equals(expectedZplOutput));
        verify(mockClient.send(any)).called(1);
      });

      // TODO: Re-enable when convertImageToGraphic method is properly implemented
      // test('converts image to EPL format', () async {
      //   // Arrange
      //   final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
      //   const fileName = 'test.png';
      //   const expectedEplOutput = 'GG20,40,"test.grf"';

      //   final mockStreamedResponse = MockStreamedResponse();
      //   when(mockStreamedResponse.statusCode).thenReturn(200);
      //   when(mockStreamedResponse.stream).thenAnswer(
      //     (_) => http.ByteStream.fromBytes(expectedEplOutput.codeUnits),
      //   );

      //   when(
      //     mockClient.send(any),
      //   ).thenAnswer((_) async => mockStreamedResponse);

      //   // Act
      //   final result = await LabelaryService.convertImageToGraphic(
      //     imageData,
      //     fileName,
      //     outputFormat: LabelaryOutputFormat.epl,
      //   );

      //   // Assert
      //   expect(result, equals(expectedEplOutput));
      // });

      test('throws exception on conversion error', () async {
        // Arrange
        final imageData = Uint8List.fromList([1, 2, 3, 4, 5]);
        const fileName = 'invalid.txt';

        final mockStreamedResponse = MockStreamedResponse();
        when(mockStreamedResponse.statusCode).thenReturn(400);
        when(mockStreamedResponse.stream).thenAnswer(
          (_) => http.ByteStream.fromBytes('Unsupported file format'.codeUnits),
        );

        when(
          mockClient.send(any),
        ).thenAnswer((_) async => mockStreamedResponse);

        // Act & Assert
        expect(
          () => LabelaryService.convertImageToGraphic(imageData, fileName),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to convert image. Status: 400'),
            ),
          ),
        );
      });
    });

    group('convertFontToZpl', () {
      test('converts TTF font to ZPL successfully', () async {
        // Arrange
        final fontData = Uint8List.fromList(
          List.generate(1000, (i) => i % 256),
        );
        const fileName = 'Roboto-Regular.ttf';
        const expectedZplOutput =
            '~DUR:ROBOTO.TTF,1000,1000\n^XA^CWZ,E:ROBOTO.TTF^XZ';

        final mockStreamedResponse = MockStreamedResponse();
        when(mockStreamedResponse.statusCode).thenReturn(200);
        when(mockStreamedResponse.stream).thenAnswer(
          (_) => http.ByteStream.fromBytes(expectedZplOutput.codeUnits),
        );

        when(
          mockClient.send(any),
        ).thenAnswer((_) async => mockStreamedResponse);

        // Act
        final result = await LabelaryService.convertFontToZpl(
          fontData,
          fileName,
        );

        // Assert
        expect(result, equals(expectedZplOutput));
        verify(mockClient.send(any)).called(1);
      });

      test('converts font with custom parameters', () async {
        // Arrange
        final fontData = Uint8List.fromList(
          List.generate(1000, (i) => i % 256),
        );
        const fileName = 'Custom-Font.ttf';
        const path = 'E:CUSTOM.TTF';
        const name = 'Z';
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        const expectedZplOutput =
            '~DUE:CUSTOM.TTF,800,800\n^XA^CWZ,E:CUSTOM.TTF^XZ';

        final mockStreamedResponse = MockStreamedResponse();
        when(mockStreamedResponse.statusCode).thenReturn(200);
        when(mockStreamedResponse.stream).thenAnswer(
          (_) => http.ByteStream.fromBytes(expectedZplOutput.codeUnits),
        );

        when(
          mockClient.send(any),
        ).thenAnswer((_) async => mockStreamedResponse);

        // Act
        final result = await LabelaryService.convertFontToZpl(
          fontData,
          fileName,
          path: path,
          name: name,
          chars: chars,
        );

        // Assert
        expect(result, equals(expectedZplOutput));
      });

      test('throws exception on font conversion error', () async {
        // Arrange
        final fontData = Uint8List.fromList([1, 2, 3]);
        const fileName = 'invalid.bin';

        final mockStreamedResponse = MockStreamedResponse();
        when(mockStreamedResponse.statusCode).thenReturn(400);
        when(mockStreamedResponse.stream).thenAnswer(
          (_) => http.ByteStream.fromBytes('Invalid font file'.codeUnits),
        );

        when(
          mockClient.send(any),
        ).thenAnswer((_) async => mockStreamedResponse);

        // Act & Assert
        expect(
          () => LabelaryService.convertFontToZpl(fontData, fileName),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Failed to convert font. Status: 400'),
            ),
          ),
        );
      });
    });

    group('URL construction verification', () {
      test('constructs correct URLs for different densities', () async {
        const testCases = [
          {'density': LabelaryPrintDensity.d6, 'expectedDensity': '6dpmm'},
          {'density': LabelaryPrintDensity.d8, 'expectedDensity': '8dpmm'},
          {'density': LabelaryPrintDensity.d12, 'expectedDensity': '12dpmm'},
          {'density': LabelaryPrintDensity.d24, 'expectedDensity': '24dpmm'},
        ];

        for (final testCase in testCases) {
          // Arrange
          const zpl = '^XA^FO50,50^A0N,50,50^FDTest^FS^XZ';
          final density = testCase['density'] as LabelaryPrintDensity;
          final expectedDensity = testCase['expectedDensity'] as String;
          final expectedUrl = Uri.parse(
            'https://api.labelary.com/v1/printers/$expectedDensity/labels/4.0x6.0/0/',
          );
          final mockResponse = http.Response.bytes(
            Uint8List.fromList([1, 2, 3, 4]),
            200,
          );

          when(
            mockClient.post(
              expectedUrl,
              headers: {'Accept': 'image/png'},
              body: zpl,
            ),
          ).thenAnswer((_) async => mockResponse);

          // Act
          await LabelaryService.renderZplSimple(
            zpl,
            density: density,
            client: mockClient,
          );

          // Assert
          verify(
            mockClient.post(
              expectedUrl,
              headers: {'Accept': 'image/png'},
              body: zpl,
            ),
          ).called(1);
        }
      });

      test('constructs correct URLs for different output formats', () async {
        const testCases = [
          {'format': LabelaryOutputFormat.png, 'expectedHeader': 'image/png'},
          {
            'format': LabelaryOutputFormat.pdf,
            'expectedHeader': 'application/pdf',
          },
          {
            'format': LabelaryOutputFormat.json,
            'expectedHeader': 'application/json',
          },
        ];

        for (final testCase in testCases) {
          // Arrange
          const zpl = '^XA^FO50,50^A0N,50,50^FDTest^FS^XZ';
          final format = testCase['format'] as LabelaryOutputFormat;
          final expectedHeader = testCase['expectedHeader'] as String;
          final expectedUrl = Uri.parse(
            'https://api.labelary.com/v1/printers/8dpmm/labels/4.0x6.0/0/',
          );
          final mockResponse = http.Response.bytes(
            Uint8List.fromList([1, 2, 3, 4]),
            200,
          );

          when(
            mockClient.post(
              expectedUrl,
              headers: {'Accept': expectedHeader},
              body: zpl,
            ),
          ).thenAnswer((_) async => mockResponse);

          // Act
          await LabelaryService.renderZplSimple(
            zpl,
            outputFormat: format,
            client: mockClient,
          );

          // Assert
          verify(
            mockClient.post(
              expectedUrl,
              headers: {'Accept': expectedHeader},
              body: zpl,
            ),
          ).called(1);
        }
      });
    });
  });
}
