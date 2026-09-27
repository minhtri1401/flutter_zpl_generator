import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'zpl_barcode_painter.dart';
import 'zpl_text_painter.dart';

/// A CustomPainter that graphically renders ZPL commands onto a Flutter canvas.
class ZplCanvasPainter extends CustomPainter {
  final ZplGenerator generator;

  ZplCanvasPainter({required this.generator});

  @override
  void paint(Canvas canvas, Size size) {
    final commands = generator.commands;
    _drawCommands(canvas, size, commands);
  }

  void _drawCommands(Canvas canvas, Size size, List<ZplCommand> commands) {
    for (final cmd in commands) {
      if (cmd is ZplBox) {
        _drawBox(canvas, cmd);
      } else if (cmd is ZplGraphicCircle) {
        _drawCircle(canvas, cmd);
      } else if (cmd is ZplGraphicEllipse) {
        _drawEllipse(canvas, cmd);
      } else if (cmd is ZplGraphicDiagonalLine) {
        _drawDiagonalLine(canvas, cmd);
      } else if (cmd is ZplSeparator) {
        _drawSeparator(canvas, cmd);
      } else if (cmd is ZplBarcode) {
        _drawBarcode(canvas, cmd);
      } else if (cmd is ZplText) {
        _drawText(canvas, cmd);
      } else if (cmd is ZplTextBlock) {
        _drawTextBlock(canvas, cmd);
      } else if (cmd is ZplImageInline) {
        _drawMonochromeFromPixels(
          canvas,
          cmd.x,
          cmd.y,
          cmd.getMonochromePixels(),
          placeholderWidth: cmd.width,
          placeholderHeight: cmd.height,
          label: 'ZplImageInline',
        );
      } else if (cmd is ZplImageRecall) {
        final download = _findDownload(commands, cmd.graphicName);
        if (download != null) {
          _drawMonochromeFromPixels(
            canvas,
            cmd.x,
            cmd.y,
            download.getMonochromePixels(),
            placeholderWidth: cmd.width ?? download.width,
            placeholderHeight: cmd.height ?? download.height,
            label: 'ZplImageRecall(${cmd.graphicName})',
          );
        } else {
          _drawFallbackText(
            canvas,
            'ZplImageRecall(${cmd.graphicName}?)',
            Offset(cmd.x.toDouble(), cmd.y.toDouble()),
          );
        }
      } else if (cmd is ZplRaw) {
        _drawRawZpl(canvas, size, cmd);
      } else if (cmd is ZplConditional) {
        if (cmd.condition) _drawCommands(canvas, size, [cmd.child]);
      } else if (cmd is ZplGraphicSymbol) {
        drawZplGraphicSymbol(canvas, cmd);
      } else if (cmd is ZplGridRow) {
        _drawCommands(
          canvas,
          size,
          cmd.getPositionedChildren(generator.config),
        );
      } else if (cmd is ZplColumn) {
        _drawCommands(
          canvas,
          size,
          cmd.getPositionedChildren(generator.config),
        );
      } else if (cmd is ZplTable) {
        _drawCommands(canvas, size, cmd.getDrawableCommands(generator.config));
      }
    }
  }

  void _drawBox(Canvas canvas, ZplBox box) {
    final paint = Paint()
      ..color = box.reversePrint ? Colors.white : Colors.black
      ..blendMode = box.reversePrint ? BlendMode.difference : BlendMode.srcOver
      ..style =
          box.borderThickness >= box.width / 2 &&
              box.borderThickness >= box.height / 2
          ? PaintingStyle.fill
          : PaintingStyle.stroke
      ..strokeWidth = box.borderThickness.toDouble();

    final inset = paint.style == PaintingStyle.stroke
        ? box.borderThickness / 2
        : 0.0;
    final rect = Rect.fromLTWH(
      box.x.toDouble() + inset,
      box.y.toDouble() + inset,
      (box.width.toDouble() - (inset * 2)).clamp(0, double.infinity),
      (box.height.toDouble() - (inset * 2)).clamp(0, double.infinity),
    );

    if (box.cornerRounding > 0) {
      final radius = Radius.circular(
        (box.cornerRounding / 8) *
            (box.width > box.height ? box.height / 2 : box.width / 2),
      );
      canvas.drawRRect(RRect.fromRectAndRadius(rect, radius), paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  void _drawCircle(Canvas canvas, ZplGraphicCircle circle) {
    final isFilled = circle.borderThickness >= circle.diameter / 2;
    final paint = Paint()
      ..color = Colors.black
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = circle.borderThickness.toDouble();

    final radius = circle.diameter / 2;
    if (isFilled) {
      canvas.drawCircle(
        Offset(circle.x + radius, circle.y + radius),
        radius,
        paint,
      );
    } else {
      final inset = circle.borderThickness / 2;
      canvas.drawCircle(
        Offset(circle.x + radius, circle.y + radius),
        radius - inset,
        paint,
      );
    }
  }

  void _drawEllipse(Canvas canvas, ZplGraphicEllipse ellipse) {
    final isFilled =
        ellipse.borderThickness >= ellipse.width / 2 &&
        ellipse.borderThickness >= ellipse.height / 2;
    final paint = Paint()
      ..color = Colors.black
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = ellipse.borderThickness.toDouble();

    final inset = paint.style == PaintingStyle.stroke
        ? ellipse.borderThickness / 2
        : 0.0;
    final rect = Rect.fromLTWH(
      ellipse.x.toDouble() + inset,
      ellipse.y.toDouble() + inset,
      (ellipse.width.toDouble() - (inset * 2)).clamp(0, double.infinity),
      (ellipse.height.toDouble() - (inset * 2)).clamp(0, double.infinity),
    );
    canvas.drawOval(rect, paint);
  }

  void _drawDiagonalLine(Canvas canvas, ZplGraphicDiagonalLine line) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = line.borderThickness.toDouble();

    if (line.orientation == 'R') {
      canvas.drawLine(
        Offset(line.x.toDouble(), line.y.toDouble() + line.height),
        Offset(line.x.toDouble() + line.width, line.y.toDouble()),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(line.x.toDouble(), line.y.toDouble()),
        Offset(line.x.toDouble() + line.width, line.y.toDouble() + line.height),
        paint,
      );
    }
  }

  void _drawSeparator(Canvas canvas, ZplSeparator separator) {
    final config = generator.config;
    final isHorizontal =
        separator.orientation == ZplOrientation.normal ||
        separator.orientation == ZplOrientation.inverted180;

    if (separator.type == ZplSeparatorType.character) {
      _drawCharacterSeparator(canvas, separator, isHorizontal, config);
    } else {
      _drawBoxSeparator(canvas, separator, isHorizontal, config);
    }
  }

  void _drawBoxSeparator(
    Canvas canvas,
    ZplSeparator separator,
    bool isHorizontal,
    ZplConfiguration config,
  ) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    if (isHorizontal) {
      final startX = (separator.x + separator.paddingLeft).toDouble();
      final lineLength =
          separator.length?.toDouble() ??
          ((separator.maxWidth ?? config.printWidth ?? 406) -
                  separator.paddingLeft -
                  separator.paddingRight)
              .toDouble();
      canvas.drawRect(
        Rect.fromLTWH(
          startX,
          separator.y.toDouble(),
          lineLength,
          separator.thickness.toDouble(),
        ),
        paint,
      );
    } else {
      final startY = (separator.y + separator.paddingTop).toDouble();
      final lineLength =
          separator.length?.toDouble() ??
          ((config.labelLength ?? 600) -
                  separator.paddingTop -
                  separator.paddingBottom)
              .toDouble();
      canvas.drawRect(
        Rect.fromLTWH(
          separator.x.toDouble(),
          startY,
          separator.thickness.toDouble(),
          lineLength,
        ),
        paint,
      );
    }
  }

  void _drawCharacterSeparator(
    Canvas canvas,
    ZplSeparator separator,
    bool isHorizontal,
    ZplConfiguration config,
  ) {
    final fh = separator.fontHeight.toDouble();
    final fw = separator.fontWidth.toDouble();
    final hScale = (fw / fh).clamp(0.5, 1.0);

    if (isHorizontal) {
      final availableWidth =
          separator.length?.toDouble() ??
          ((separator.maxWidth ?? config.printWidth ?? 406) -
                  separator.paddingLeft -
                  separator.paddingRight)
              .toDouble();
      final charCount = (availableWidth / fw).floor();
      final text = separator.character * charCount;

      final textPainter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: Colors.black,
            fontSize: fh,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      final startX = (separator.x + separator.paddingLeft).toDouble();
      canvas.save();
      canvas.translate(startX, separator.y.toDouble());
      canvas.scale(hScale, 1.0);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    } else {
      final availableHeight =
          separator.length?.toDouble() ??
          ((config.labelLength ?? 600) -
                  separator.paddingTop -
                  separator.paddingBottom)
              .toDouble();
      final charCount = (availableHeight / fh).floor();

      for (int i = 0; i < charCount; i++) {
        final charY =
            separator.y + separator.paddingTop + (i * separator.fontHeight);
        final textPainter = TextPainter(
          text: TextSpan(
            text: separator.character,
            style: TextStyle(
              color: Colors.black,
              fontSize: fh,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(separator.x.toDouble(), charY.toDouble()),
        );
      }
    }
  }

  void _drawBarcode(Canvas canvas, ZplBarcode zplBarcode) =>
      drawZplBarcode(canvas, zplBarcode, generator.config);

  void _drawText(Canvas canvas, ZplText text) =>
      drawZplText(canvas, text, generator.config);

  void _drawTextBlock(Canvas canvas, ZplTextBlock textBlock) =>
      drawZplTextBlock(canvas, textBlock);

  /// Shared pixel-grid renderer used by ZplImage (legacy), ZplImageInline and
  /// ZplImageRecall. When [monochrome] is null falls back to a cyan
  /// placeholder rectangle sized by [placeholderWidth]/[placeholderHeight].
  void _drawMonochromeFromPixels(
    Canvas canvas,
    int x,
    int y,
    ({int width, int height, List<bool> pixels})? monochrome, {
    required int placeholderWidth,
    required int placeholderHeight,
    required String label,
  }) {
    if (monochrome != null) {
      final pixels = monochrome.pixels;
      final w = monochrome.width;
      final h = monochrome.height;
      final startX = x.toDouble();
      final startY = y.toDouble();
      final paint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      for (int py = 0; py < h; py++) {
        int runStartX = -1;
        for (int px = 0; px < w; px++) {
          if (pixels[py * w + px]) {
            if (runStartX == -1) runStartX = px;
          } else {
            if (runStartX != -1) {
              canvas.drawRect(
                Rect.fromLTWH(
                  startX + runStartX,
                  startY + py.toDouble(),
                  (px - runStartX).toDouble(),
                  1,
                ),
                paint,
              );
              runStartX = -1;
            }
          }
        }
        if (runStartX != -1) {
          canvas.drawRect(
            Rect.fromLTWH(
              startX + runStartX,
              startY + py.toDouble(),
              (w - runStartX).toDouble(),
              1,
            ),
            paint,
          );
        }
      }
      return;
    }

    final paint = Paint()
      ..color = const Color(0x4D00BCD4)
      ..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(
      x.toDouble(),
      y.toDouble(),
      placeholderWidth > 0 ? placeholderWidth.toDouble() : 100,
      placeholderHeight > 0 ? placeholderHeight.toDouble() : 100,
    );
    canvas.drawRect(rect, paint);
    _drawFallbackText(canvas, label, rect.topLeft + const Offset(5, 5));
  }

  ZplImageDownload? _findDownload(List<ZplCommand> all, String name) {
    for (final c in all) {
      if (c is ZplImageDownload && c.graphicName == name) return c;
    }
    return null;
  }

  void _drawFallbackText(Canvas canvas, String text, Offset offset) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  void _drawRawZpl(Canvas canvas, Size size, ZplRaw raw) {
    // A simple regex parser for basic FO, FD, GB, A0 shapes, ONLY for preview purposes
    final command = raw.command;
    int currentX = 0;
    int currentY = 0;
    int fontHeight = 20;
    int fontWidth = 20;

    final regex = RegExp(r'\^([A-Z0-9]{2})([^/^~]*)');
    final matches = regex.allMatches(command);

    for (final match in matches) {
      final cmd = match.group(1)!;
      final argsStr = match.group(2) ?? '';
      final args = argsStr.split(',').map((e) => e.trim()).toList();

      if (cmd == 'FO') {
        currentX = int.tryParse(args.isNotEmpty ? args[0] : '0') ?? 0;
        currentY = int.tryParse(args.length > 1 ? args[1] : '0') ?? 0;
      } else if (cmd == 'A0' ||
          cmd == 'A@' ||
          cmd == 'AN' ||
          cmd.startsWith('A')) {
        fontHeight = int.tryParse(args.length > 1 ? args[1] : '0') ?? 20;
        fontWidth = int.tryParse(args.length > 2 ? args[2] : '0') ?? 20;
      } else if (cmd == 'GB') {
        // Graphic Box
        final width = int.tryParse(args.isNotEmpty ? args[0] : '0') ?? 0;
        final height = int.tryParse(args.length > 1 ? args[1] : '0') ?? 0;
        final border = int.tryParse(args.length > 2 ? args[2] : '0') ?? 1;
        _drawBox(
          canvas,
          ZplBox(
            x: currentX,
            y: currentY,
            width: width,
            height: height,
            borderThickness: border,
          ),
        );
      } else if (cmd == 'FD') {
        // Field Data
        _drawText(
          canvas,
          ZplText(
            x: currentX,
            y: currentY,
            text: argsStr,
            fontHeight: fontHeight,
            fontWidth: fontWidth,
          ),
        );
      } else if (cmd == 'FR') {
        // Limited support: can't easily affect previous or next blindly here usually without nesting,
        // but since this is raw escape hatch preview, we just parse the next known nodes if needed.
      }
    }
  }

  @override
  bool shouldRepaint(covariant ZplCanvasPainter oldDelegate) =>
      oldDelegate.generator != generator;
}
