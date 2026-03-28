import 'package:flutter/material.dart';
import 'package:flutter_zpl_generator/flutter_zpl_generator.dart';
import 'package:barcode/barcode.dart';

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
      } else if (cmd is ZplImage) {
        _drawImagePlaceholder(canvas, cmd);
      } else if (cmd is ZplRaw) {
        _drawRawZpl(canvas, size, cmd);
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

  void _drawBarcode(Canvas canvas, ZplBarcode zplBarcode) {
    Barcode? barcode;
    if (zplBarcode.type == ZplBarcodeType.code128) {
      barcode = Barcode.code128();
    } else if (zplBarcode.type == ZplBarcodeType.code39) {
      barcode = Barcode.code39();
    } else if (zplBarcode.type == ZplBarcodeType.ean13) {
      barcode = Barcode.ean13();
    } else if (zplBarcode.type == ZplBarcodeType.upcA) {
      barcode = Barcode.upcA();
    } else if (zplBarcode.type == ZplBarcodeType.qrCode) {
      barcode = Barcode.qrCode();
    } else if (zplBarcode.type == ZplBarcodeType.dataMatrix) {
      barcode = Barcode.dataMatrix();
    } else {
      barcode = Barcode.code128();
    }

    final canvasWidth = generator.config.printWidth?.toDouble() ?? 406.0;
    final bool is2D =
        zplBarcode.type == ZplBarcodeType.qrCode ||
        zplBarcode.type == ZplBarcodeType.dataMatrix;

    // Use the barcode's calculated width getter (accounts for type, data length, module width)
    final double renderWidth = zplBarcode.width.toDouble();
    final double renderHeight = is2D
        ? renderWidth
        : (zplBarcode.height > 0 ? zplBarcode.height.toDouble() : 50.0);

    // X alignment
    double drawX = zplBarcode.x.toDouble();
    if (zplBarcode.alignment != null) {
      final labelWidth = (zplBarcode.maxWidth?.toDouble() ?? canvasWidth);
      switch (zplBarcode.alignment!) {
        case ZplAlignment.center:
          drawX =
              zplBarcode.x +
              ((labelWidth - renderWidth) / 2).clamp(0, labelWidth);
        case ZplAlignment.right:
          drawX =
              zplBarcode.x + (labelWidth - renderWidth).clamp(0, labelWidth);
        case ZplAlignment.left:
          drawX = zplBarcode.x.toDouble();
      }
    }

    try {
      final drawText = zplBarcode.printInterpretationLine;
      final drawTextAbove = zplBarcode.printInterpretationLineAbove;

      final elements = barcode.make(
        zplBarcode.data,
        width: renderWidth,
        height: renderHeight,
        drawText: drawText,
        fontHeight: drawText ? 24.0 : null,
      );

      canvas.save();
      final yOffset = (drawText && drawTextAbove) ? 24.0 : 0.0;
      canvas.translate(drawX, zplBarcode.y.toDouble() + yOffset);

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = false;
      for (final el in elements) {
        if (el is BarcodeBar) {
          paint.color = el.black ? Colors.black : Colors.white;
          canvas.drawRect(
            Rect.fromLTWH(el.left, el.top, el.width, el.height),
            paint,
          );
        }
      }

      if (drawText) {
        for (final el in elements) {
          if (el is BarcodeText) {
            final textPainter = TextPainter(
              text: TextSpan(
                text: el.text,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'monospace',
                ),
              ),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.center,
            );
            textPainter.layout(
              minWidth: el.width,
              maxWidth: el.width > 0 ? el.width : double.infinity,
            );

            final textY = drawTextAbove ? el.top - renderHeight - 24.0 : el.top;
            textPainter.paint(canvas, Offset(el.left, textY));
          }
        }
      }
      canvas.restore();
    } catch (e) {
      final paint = Paint()..color = const Color(0x809E9E9E);
      canvas.drawRect(
        Rect.fromLTWH(drawX, zplBarcode.y.toDouble(), 100, 50),
        paint,
      );
      _drawFallbackText(
        canvas,
        'Err: $e',
        Offset(drawX, zplBarcode.y.toDouble()),
      );
    }
  }

  void _drawText(Canvas canvas, ZplText text) {
    final fh = (text.fontHeight ?? 20).toDouble();
    final fw = (text.fontWidth ?? (fh * 0.6).round()).toDouble();

    // ZPL fonts render narrower than Flutter's proportional font.
    // Compress horizontally by the font aspect ratio (always <= 1.0).
    final hScale = (fw / fh).clamp(0.5, 1.0);

    // Line height: account for lineSpacing when multi-line
    final lineHeight = text.maxLines > 1 && text.lineSpacing > 0
        ? (fh + text.lineSpacing) / fh
        : 1.0;

    TextAlign getTextAlign() {
      switch (text.alignment) {
        case ZplAlignment.center:
          return TextAlign.center;
        case ZplAlignment.right:
          return TextAlign.right;
        default:
          return TextAlign.left;
      }
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: text.text,
        style: TextStyle(
          foreground: Paint()
            ..color = text.reversePrint ? Colors.white : Colors.black
            ..blendMode = text.reversePrint
                ? BlendMode.difference
                : BlendMode.srcOver,
          fontSize: fh,
          fontWeight: FontWeight.w600,
          height: lineHeight,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: text.maxLines > 1 ? text.maxLines : null,
      ellipsis: text.maxLines > 1 ? '\u2026' : null,
      textAlign: getTextAlign(),
    );

    // When maxWidth is set, use it. Otherwise for multi-line text,
    // fall back to available width (printWidth - x position).
    final wrapWidth =
        text.maxWidth?.toDouble() ??
        (text.maxLines > 1
            ? (generator.config.printWidth ?? 406).toDouble() -
                  text.x.toDouble()
            : null);

    final effectiveMaxWidth = wrapWidth != null
        ? wrapWidth / hScale
        : double.infinity;
    textPainter.layout(
      minWidth: wrapWidth != null ? effectiveMaxWidth : 0,
      maxWidth: effectiveMaxWidth,
    );

    final scaledWidth = textPainter.width * hScale;

    double drawX = text.x.toDouble();
    if (text.alignment != null && text.maxWidth == null) {
      final labelWidth = (generator.config.printWidth ?? 406).toDouble();
      if (text.x == 0) {
        switch (text.alignment!) {
          case ZplAlignment.center:
            drawX = ((labelWidth - scaledWidth) / 2).clamp(0, labelWidth);
          case ZplAlignment.right:
            drawX = (labelWidth - scaledWidth).clamp(0, labelWidth);
          case ZplAlignment.left:
            drawX = text.paddingLeft.toDouble();
        }
      }
    }

    canvas.save();
    canvas.translate(drawX, text.y.toDouble());
    canvas.scale(hScale, 1.0);
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void _drawTextBlock(Canvas canvas, ZplTextBlock textBlock) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: textBlock.text,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: textBlock.maxWidth.toDouble());
    textPainter.paint(
      canvas,
      Offset(textBlock.x.toDouble(), textBlock.y.toDouble()),
    );
  }

  void _drawImagePlaceholder(Canvas canvas, ZplImage imageCmd) {
    try {
      final monochrome = imageCmd.getMonochromePixels();
      if (monochrome != null) {
        final pixels = monochrome.pixels;
        final w = monochrome.width;
        final h = monochrome.height;
        final startX = imageCmd.x.toDouble();
        final startY = imageCmd.y.toDouble();

        final paint = Paint()
          ..color = Colors.black
          ..style = PaintingStyle.fill
          ..isAntiAlias = false;

        // Draw by coalescing horizontal pixels into rects for performance
        for (int y = 0; y < h; y++) {
          int runStartX = -1;
          for (int x = 0; x < w; x++) {
            if (pixels[y * w + x]) {
              if (runStartX == -1) runStartX = x;
            } else {
              if (runStartX != -1) {
                canvas.drawRect(
                  Rect.fromLTWH(
                    startX + runStartX,
                    startY + y.toDouble(),
                    (x - runStartX).toDouble(),
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
                startY + y.toDouble(),
                (w - runStartX).toDouble(),
                1,
              ),
              paint,
            );
          }
        }
        return; // Early return to avoid drawing placeholder
      }
    } catch (e) {
      // Fallback silently to placeholder
    }

    final paint = Paint()
      // Colors.cyan with 30% opacity
      ..color = const Color(0x4D00BCD4)
      ..style = PaintingStyle.fill;

    // Fallback gracefully since targetWidth may be null or non-null. Let's just use ??
    final width =
        (imageCmd.targetWidth != null && imageCmd.targetWidth! > 0
                ? imageCmd.targetWidth!
                : 100)
            .toDouble();
    final height =
        (imageCmd.targetHeight != null && imageCmd.targetHeight! > 0
                ? imageCmd.targetHeight!
                : 100)
            .toDouble();

    final rect = Rect.fromLTWH(
      imageCmd.x.toDouble(),
      imageCmd.y.toDouble(),
      width,
      height,
    );
    canvas.drawRect(rect, paint);

    _drawFallbackText(canvas, "ZplImage", rect.topLeft + const Offset(5, 5));
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
