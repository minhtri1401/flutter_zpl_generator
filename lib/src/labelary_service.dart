import 'dart:typed_data';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:http/http.dart' as http;

/// Class to represent page layout configuration for PDF generation.
class LabelaryPageLayout {
  final int columns;
  final int rows;

  const LabelaryPageLayout({required this.columns, required this.rows});

  String get value => '${columns}x$rows';
}

/// Class to represent a parsed linting warning from the Labelary API.
class LabelaryWarning {
  final int byteIndex;
  final int byteSize;
  final String? commandName;
  final int? parameterNumber;
  final String message;

  const LabelaryWarning({
    required this.byteIndex,
    required this.byteSize,
    this.commandName,
    this.parameterNumber,
    required this.message,
  });

  /// Parses a warning from the pipe-delimited format returned by Labelary.
  factory LabelaryWarning.fromString(String warningString) {
    final parts = warningString.split('|');
    if (parts.length != 5) {
      throw ArgumentError('Invalid warning format: $warningString');
    }

    return LabelaryWarning(
      byteIndex: int.parse(parts[0]),
      byteSize: int.parse(parts[1]),
      commandName: parts[2].isEmpty ? null : parts[2],
      parameterNumber: parts[3].isEmpty ? null : int.parse(parts[3]),
      message: parts[4],
    );
  }

  @override
  String toString() {
    return 'LabelaryWarning(byteIndex: $byteIndex, byteSize: $byteSize, '
        'commandName: $commandName, parameterNumber: $parameterNumber, '
        'message: "$message")';
  }
}

/// Class to represent the response from Labelary API with additional metadata.
class LabelaryResponse {
  final Uint8List data;
  final int? totalCount;
  final List<LabelaryWarning> warnings;

  const LabelaryResponse({
    required this.data,
    this.totalCount,
    this.warnings = const [],
  });
}

/// A service class to interact with the Labelary.com API.
class LabelaryService {
  static const String _baseUrl = 'https://api.labelary.com/v1/printers';

  /// Renders a ZPL script string into an image or other format using the Labelary API.
  ///
  /// This method sends raw ZPL string using POST with `application/x-www-form-urlencoded` content type.
  /// The ZPL string is sent directly in the request body as specified in the Labelary API documentation.
  ///
  /// [zpl] The ZPL script string to render
  /// [density] Print density (6, 8, 12, or 24 dots per mm)
  /// [width] Label width in inches
  /// [height] Label height in inches
  /// [outputFormat] Output format (PNG, PDF, etc.)
  /// [index] Label index to return (for multi-label outputs). If null and outputFormat is PDF, returns all labels
  /// [rotation] Rotate the label image clockwise (0, 90, 180, or 270 degrees)
  /// [pageSize] PDF page size (only for PDF output)
  /// [pageOrientation] PDF page orientation (only for PDF output)
  /// [pageLayout] PDF page layout as columns x rows (only for PDF output)
  /// [pageAlign] PDF horizontal alignment (only for PDF output)
  /// [pageVerticalAlign] PDF vertical alignment (only for PDF output)
  /// [labelBorder] PDF label border style (only for PDF output)
  /// [printQuality] PNG image quality (only for PNG output)
  /// [enableLinting] Enable ZPL linting to check for potential errors
  /// [client] HTTP client for testing purposes
  static Future<LabelaryResponse> renderZpl(
    String zpl, {
    LabelaryPrintDensity density = LabelaryPrintDensity.d8,
    double width = 4,
    double height = 6,
    LabelaryOutputFormat outputFormat = LabelaryOutputFormat.png,
    int? index = 0,
    LabelaryRotation? rotation,
    LabelaryPageSize? pageSize,
    LabelaryPageOrientation? pageOrientation,
    LabelaryPageLayout? pageLayout,
    LabelaryPageAlign? pageAlign,
    LabelaryPageAlign? pageVerticalAlign,
    LabelaryLabelBorder? labelBorder,
    LabelaryPrintQuality? printQuality,
    bool enableLinting = false,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      // Build URL - omit index for PDF with all labels
      final urlPath = index != null
          ? '$_baseUrl/${density.value}/labels/${width}x$height/$index/'
          : '$_baseUrl/${density.value}/labels/${width}x$height/';
      final url = Uri.parse(urlPath);

      final headers = <String, String>{
        'Accept': outputFormat.acceptHeader,
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      // Add advanced headers
      if (rotation != null) {
        headers['X-Rotation'] = rotation.degrees.toString();
      }

      // PDF-specific headers
      if (outputFormat == LabelaryOutputFormat.pdf) {
        if (pageSize != null) {
          headers['X-Page-Size'] = pageSize.value;
        }
        if (pageOrientation != null) {
          headers['X-Page-Orientation'] = pageOrientation.value;
        }
        if (pageLayout != null) {
          headers['X-Page-Layout'] = pageLayout.value;
        }
        if (pageAlign != null) {
          headers['X-Page-Align'] = pageAlign.value;
        }
        if (pageVerticalAlign != null) {
          headers['X-Page-Vertical-Align'] = pageVerticalAlign.value;
        }
        if (labelBorder != null) {
          headers['X-Label-Border'] = labelBorder.value;
        }
      }

      // PNG-specific headers
      if (outputFormat == LabelaryOutputFormat.png && printQuality != null) {
        headers['X-Quality'] = printQuality.value;
      }

      // Linting header
      if (enableLinting) {
        headers['X-Linter'] = 'On';
      }

      final response = await httpClient.post(url, headers: headers, body: zpl);
      print(zpl);
      if (response.statusCode == 200) {
        // Parse response headers
        final totalCount = response.headers['x-total-count'] != null
            ? int.tryParse(response.headers['x-total-count']!)
            : null;

        final warnings = <LabelaryWarning>[];
        final warningsHeader = response.headers['x-warnings'];
        if (warningsHeader != null && warningsHeader.isNotEmpty) {
          try {
            // Warnings are pipe-delimited, but each warning itself contains 5 pipe-separated fields
            // So we need to split by groups of 5 fields
            final parts = warningsHeader.split('|');
            for (int i = 0; i < parts.length; i += 5) {
              if (i + 4 < parts.length) {
                final warningParts = parts.sublist(i, i + 5);
                final warningString = warningParts.join('|');
                warnings.add(LabelaryWarning.fromString(warningString));
              }
            }
          } catch (e) {
            // If warning parsing fails, continue without warnings
          }
        }

        return LabelaryResponse(
          data: response.bodyBytes,
          totalCount: totalCount,
          warnings: warnings,
        );
      } else {
        throw Exception(
          'Failed to render ZPL. Status: ${response.statusCode}, Body: ${response.body}',
        );
      }
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Renders a ZPL file into an image or other format using the Labelary API.
  ///
  /// This method uploads a ZPL file using POST with `multipart/form-data` content type.
  /// The ZPL content is sent as a file parameter as specified in the Labelary API documentation.
  ///
  /// [zplFileData] The ZPL file data as bytes
  /// [filename] The filename for the ZPL file (e.g., 'label.zpl')
  /// [density] Print density (6, 8, 12, or 24 dots per mm)
  /// [width] Label width in inches
  /// [height] Label height in inches
  /// [outputFormat] Output format (PNG, PDF, etc.)
  /// [index] Label index to return (for multi-label outputs). If null and outputFormat is PDF, returns all labels
  /// [rotation] Rotate the label image clockwise (0, 90, 180, or 270 degrees)
  /// [pageSize] PDF page size (only for PDF output)
  /// [pageOrientation] PDF page orientation (only for PDF output)
  /// [pageLayout] PDF page layout as columns x rows (only for PDF output)
  /// [pageAlign] PDF horizontal alignment (only for PDF output)
  /// [pageVerticalAlign] PDF vertical alignment (only for PDF output)
  /// [labelBorder] PDF label border style (only for PDF output)
  /// [printQuality] PNG image quality (only for PNG output)
  /// [enableLinting] Enable ZPL linting to check for potential errors
  /// [client] HTTP client for testing purposes
  static Future<LabelaryResponse> renderZplFile(
    Uint8List zplFileData,
    String filename, {
    LabelaryPrintDensity density = LabelaryPrintDensity.d8,
    double width = 4,
    double height = 6,
    LabelaryOutputFormat outputFormat = LabelaryOutputFormat.png,
    int? index = 0,
    LabelaryRotation? rotation,
    LabelaryPageSize? pageSize,
    LabelaryPageOrientation? pageOrientation,
    LabelaryPageLayout? pageLayout,
    LabelaryPageAlign? pageAlign,
    LabelaryPageAlign? pageVerticalAlign,
    LabelaryLabelBorder? labelBorder,
    LabelaryPrintQuality? printQuality,
    bool enableLinting = false,
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();
    try {
      // Build URL - omit index for PDF with all labels
      final urlPath = index != null
          ? '$_baseUrl/${density.value}/labels/${width}x$height/$index/'
          : '$_baseUrl/${density.value}/labels/${width}x$height/';
      final url = Uri.parse(urlPath);

      final request = http.MultipartRequest('POST', url);
      request.headers['Accept'] = outputFormat.acceptHeader;

      // Add advanced headers
      if (rotation != null) {
        request.headers['X-Rotation'] = rotation.degrees.toString();
      }

      // PDF-specific headers
      if (outputFormat == LabelaryOutputFormat.pdf) {
        if (pageSize != null) {
          request.headers['X-Page-Size'] = pageSize.value;
        }
        if (pageOrientation != null) {
          request.headers['X-Page-Orientation'] = pageOrientation.value;
        }
        if (pageLayout != null) {
          request.headers['X-Page-Layout'] = pageLayout.value;
        }
        if (pageAlign != null) {
          request.headers['X-Page-Align'] = pageAlign.value;
        }
        if (pageVerticalAlign != null) {
          request.headers['X-Page-Vertical-Align'] = pageVerticalAlign.value;
        }
        if (labelBorder != null) {
          request.headers['X-Label-Border'] = labelBorder.value;
        }
      }

      // PNG-specific headers
      if (outputFormat == LabelaryOutputFormat.png && printQuality != null) {
        request.headers['X-Quality'] = printQuality.value;
      }

      // Linting header
      if (enableLinting) {
        request.headers['X-Linter'] = 'On';
      }

      request.files.add(
        http.MultipartFile.fromBytes('file', zplFileData, filename: filename),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        // Parse response headers
        final totalCount = response.headers['x-total-count'] != null
            ? int.tryParse(response.headers['x-total-count']!)
            : null;

        final warnings = <LabelaryWarning>[];
        final warningsHeader = response.headers['x-warnings'];
        if (warningsHeader != null && warningsHeader.isNotEmpty) {
          try {
            // Warnings are pipe-delimited, but each warning itself contains 5 pipe-separated fields
            // So we need to split by groups of 5 fields
            final parts = warningsHeader.split('|');
            for (int i = 0; i < parts.length; i += 5) {
              if (i + 4 < parts.length) {
                final warningParts = parts.sublist(i, i + 5);
                final warningString = warningParts.join('|');
                warnings.add(LabelaryWarning.fromString(warningString));
              }
            }
          } catch (e) {
            // If warning parsing fails, continue without warnings
          }
        }

        final data = await response.stream.toBytes();
        return LabelaryResponse(
          data: data,
          totalCount: totalCount,
          warnings: warnings,
        );
      } else {
        final body = await response.stream.bytesToString();
        throw Exception(
          'Failed to render ZPL file. Status: ${response.statusCode}, Body: $body',
        );
      }
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Converts an image file into a ZPL graphic command string (~DG) using the Labelary API.
  ///
  /// [imageData] The raw byte data of the image file (e.g., PNG, JPG).
  /// [imageFileName] The name of the file, e.g., 'image.png'.
  /// [outputFormat] The desired command language output.
  ///
  /// Returns a [String] containing the ZPL (or other language) script.
  static Future<String> convertImageToGraphic(
    Uint8List imageData,
    String imageFileName, {
    LabelaryOutputFormat outputFormat = LabelaryOutputFormat.zpl,
  }) async {
    final url = Uri.parse('$_baseUrl/graphics');
    final request = http.MultipartRequest('POST', url);

    request.headers['Accept'] = outputFormat.acceptHeader;
    request.files.add(
      http.MultipartFile.fromBytes('file', imageData, filename: imageFileName),
    );

    final response = await request.send();

    if (response.statusCode == 200) {
      return await response.stream.bytesToString();
    } else {
      final body = await response.stream.bytesToString();
      throw Exception(
        'Failed to convert image. Status: ${response.statusCode}, Body: $body',
      );
    }
  }

  /// Converts a TrueType Font (.TTF) file into ZPL font commands (~DU, ^CW) using the Labelary API.
  ///
  /// [fontData] The raw byte data of the .TTF file.
  /// [fontFileName] The name of the file, e.g., 'MyFont.ttf'.
  /// [path] Optional: The printer path to use (e.g., 'E:MYFONT.TTF').
  /// [name] Optional: The single-letter shorthand name to assign (e.g., 'Z').
  /// [chars] Optional: A string of characters to subset the font, reducing its size.
  ///
  /// Returns a [String] containing the ZPL script for downloading the font.
  static Future<String> convertFontToZpl(
    Uint8List fontData,
    String fontFileName, {
    String? path,
    String? name,
    String? chars,
  }) async {
    final url = Uri.parse('$_baseUrl/fonts');
    final request = http.MultipartRequest('POST', url);

    request.files.add(
      http.MultipartFile.fromBytes('file', fontData, filename: fontFileName),
    );

    if (path != null) request.fields['path'] = path;
    if (name != null) request.fields['name'] = name;
    if (chars != null) request.fields['chars'] = chars;

    final response = await request.send();

    if (response.statusCode == 200) {
      return await response.stream.bytesToString();
    } else {
      final body = await response.stream.bytesToString();
      throw Exception(
        'Failed to convert font. Status: ${response.statusCode}, Body: $body',
      );
    }
  }

  /// A convenience method to render a label directly from a [ZplGenerator] instance.
  ///
  /// This method automatically extracts the width, height, and density from the
  /// [ZplConfiguration] command within the generator's command list and renders
  /// the generated ZPL string using the [renderZpl] method.
  ///
  /// [generator] The ZplGenerator containing the label commands
  /// [outputFormat] The desired output format (PNG, PDF, etc.)
  /// [index] Label index to return (for multi-label outputs). If null and outputFormat is PDF, returns all labels
  /// [rotation] Rotate the label image clockwise (0, 90, 180, or 270 degrees)
  /// [pageSize] PDF page size (only for PDF output)
  /// [pageOrientation] PDF page orientation (only for PDF output)
  /// [pageLayout] PDF page layout as columns x rows (only for PDF output)
  /// [pageAlign] PDF horizontal alignment (only for PDF output)
  /// [pageVerticalAlign] PDF vertical alignment (only for PDF output)
  /// [labelBorder] PDF label border style (only for PDF output)
  /// [printQuality] PNG image quality (only for PNG output)
  /// [enableLinting] Enable ZPL linting to check for potential errors
  /// [client] HTTP client for testing purposes
  ///
  /// Throws an error if a [ZplConfiguration] is not found in the command list.
  static Future<LabelaryResponse> renderFromGenerator(
    ZplGenerator generator, {
    LabelaryOutputFormat outputFormat = LabelaryOutputFormat.png,
    int? index = 0,
    LabelaryRotation? rotation,
    LabelaryPageSize? pageSize,
    LabelaryPageOrientation? pageOrientation,
    LabelaryPageLayout? pageLayout,
    LabelaryPageAlign? pageAlign,
    LabelaryPageAlign? pageVerticalAlign,
    LabelaryLabelBorder? labelBorder,
    LabelaryPrintQuality? printQuality,
    bool enableLinting = false,
    http.Client? client,
  }) async {
    final config =
        generator.commands.firstWhere(
              (cmd) => cmd is ZplConfiguration,
              orElse: () => throw Exception(
                'ZplConfiguration must be provided in the command list.',
              ),
            )
            as ZplConfiguration;

    final densityDpi = config.printDensity?.dpi ?? 203;
    final widthInches = (config.printWidth ?? 406) / densityDpi;
    final heightInches = (config.labelLength ?? 203) / densityDpi;
    final density = _mapZplDensityToLabelaryDensity(config.printDensity);
    final zpl = generator.build();

    return renderZpl(
      zpl,
      density: density,
      width: widthInches,
      height: heightInches,
      outputFormat: outputFormat,
      index: index,
      rotation: rotation,
      pageSize: pageSize,
      pageOrientation: pageOrientation,
      pageLayout: pageLayout,
      pageAlign: pageAlign,
      pageVerticalAlign: pageVerticalAlign,
      labelBorder: labelBorder,
      printQuality: printQuality,
      enableLinting: enableLinting,
      client: client,
    );
  }

  // Convenience methods for backward compatibility that return just the image data

  /// Convenience method to render ZPL string and return only the image data (backward compatibility).
  static Future<Uint8List> renderZplSimple(
    String zpl, {
    LabelaryPrintDensity density = LabelaryPrintDensity.d8,
    double width = 4,
    double height = 6,
    LabelaryOutputFormat outputFormat = LabelaryOutputFormat.png,
    int index = 0,
    http.Client? client,
  }) async {
    final response = await renderZpl(
      zpl,
      density: density,
      width: width,
      height: height,
      outputFormat: outputFormat,
      index: index,
      client: client,
    );
    return response.data;
  }

  /// Convenience method to render ZPL file and return only the image data (backward compatibility).
  static Future<Uint8List> renderZplFileSimple(
    Uint8List zplFileData,
    String filename, {
    LabelaryPrintDensity density = LabelaryPrintDensity.d8,
    double width = 4,
    double height = 6,
    LabelaryOutputFormat outputFormat = LabelaryOutputFormat.png,
    int index = 0,
    http.Client? client,
  }) async {
    final response = await renderZplFile(
      zplFileData,
      filename,
      density: density,
      width: width,
      height: height,
      outputFormat: outputFormat,
      index: index,
      client: client,
    );
    return response.data;
  }

  /// Convenience method to render from generator and return only the image data (backward compatibility).
  static Future<Uint8List> renderFromGeneratorSimple(
    ZplGenerator generator, {
    LabelaryOutputFormat outputFormat = LabelaryOutputFormat.png,
    int index = 0,
    http.Client? client,
  }) async {
    final response = await renderFromGenerator(
      generator,
      outputFormat: outputFormat,
      index: index,
      client: client,
    );
    return response.data;
  }

  /// Helper to map our internal density enum to the Labelary-specific one.
  static LabelaryPrintDensity _mapZplDensityToLabelaryDensity(
    ZplPrintDensity? density,
  ) {
    switch (density) {
      case ZplPrintDensity.d6:
        return LabelaryPrintDensity.d6;
      case ZplPrintDensity.d8:
        return LabelaryPrintDensity.d8;
      case ZplPrintDensity.d12:
        return LabelaryPrintDensity.d12;
      case ZplPrintDensity.d24:
        return LabelaryPrintDensity.d24;
      default:
        return LabelaryPrintDensity.d8; // Default fallback
    }
  }
}
