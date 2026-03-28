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
      } else if (cmd is ZplBarcode) {
        _drawBarcode(canvas, cmd);
      } else if (cmd is ZplText) {
        _drawText(canvas, cmd);
      } else if (cmd is ZplTextBlock) {
        _drawTextBlock(canvas, cmd);
      } else if (cmd is ZplImage) {
        _drawImagePlaceholder(canvas, cmd);
      } else if (cmd is ZplGridRow) {
        _drawCommands(canvas, size, cmd.children.map((c) => c.child).toList());
      } else if (cmd is ZplColumn) {
        _drawCommands(canvas, size, cmd.children);
      }
    }
  }

  void _drawBox(Canvas canvas, ZplBox box) {
    final paint = Paint()
      ..color = box.reversePrint ? Colors.white : Colors.black
      ..style =
          box.borderThickness >= box.width / 2 &&
              box.borderThickness >= box.height / 2
          ? PaintingStyle.fill
          : PaintingStyle.stroke
      ..strokeWidth = box.borderThickness.toDouble();

    final rect = Rect.fromLTWH(
      box.x.toDouble(),
      box.y.toDouble(),
      box.width.toDouble(),
      box.height.toDouble(),
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
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = circle.borderThickness.toDouble();

    final radius = circle.diameter / 2;
    canvas.drawCircle(
      Offset(circle.x + radius, circle.y + radius),
      radius,
      paint,
    );
  }

  void _drawEllipse(Canvas canvas, ZplGraphicEllipse ellipse) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = ellipse.borderThickness.toDouble();

    final rect = Rect.fromLTWH(
      ellipse.x.toDouble(),
      ellipse.y.toDouble(),
      ellipse.width.toDouble(),
      ellipse.height.toDouble(),
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

  void _drawBarcode(Canvas canvas, ZplBarcode zplBarcode) {
    Barcode? barcode;
    if (zplBarcode.type == ZplBarcodeType.code128) {
      barcode = Barcode.code128();
    } else if (zplBarcode.type == ZplBarcodeType.code39) {
      barcode = Barcode.code39();
    } else if (zplBarcode.type == ZplBarcodeType.ean13) {
      barcode = Barcode.ean13();
    } else if (zplBarcode.type == ZplBarcodeType.qrCode) {
      barcode = Barcode.qrCode();
    } else if (zplBarcode.type == ZplBarcodeType.dataMatrix) {
      barcode = Barcode.dataMatrix();
    } else {
      barcode = Barcode.code128();
    }

    final canvasWidth = generator.config.printWidth?.toDouble() ?? 406.0;
    // zplBarcode.maxWidth can be null or 0, fallback to a nominal width or remaining canvas width
    final safeWidth = (zplBarcode.maxWidth != null && zplBarcode.maxWidth! > 0)
        ? zplBarcode.maxWidth!.toDouble()
        : (canvasWidth - zplBarcode.x > 50
              ? canvasWidth - zplBarcode.x
              : 200.0);

    final safeHeight = zplBarcode.height > 0
        ? zplBarcode.height.toDouble()
        : 50.0;

    final rect = Rect.fromLTWH(
      zplBarcode.x.toDouble(),
      zplBarcode.y.toDouble(),
      safeWidth,
      safeHeight,
    );

    try {
      final elements = barcode.make(
        zplBarcode.data,
        width: rect.width,
        height: rect.height,
        drawText: zplBarcode.printInterpretationLine,
      );

      final paint = Paint()..color = Colors.black;
      for (final el in elements) {
        if (el is BarcodeBar) {
          canvas.drawRect(
            Rect.fromLTWH(
              zplBarcode.x + el.left,
              zplBarcode.y + el.top,
              el.width,
              el.height,
            ),
            paint,
          );
        } else if (el is BarcodeText) {
          _drawFallbackText(
            canvas,
            el.text,
            Offset(zplBarcode.x + el.left, zplBarcode.y + el.top),
          );
        }
      }
    } catch (e) {
      final paint = Paint()
        ..color = const Color(0x809E9E9E); // Colors.grey with 50% opacity
      canvas.drawRect(rect, paint);
      _drawFallbackText(canvas, "Barcode [${zplBarcode.type}]", rect.topLeft);
    }
  }

  void _drawText(Canvas canvas, ZplText text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text.text,
        style: TextStyle(
          color: text.reversePrint ? Colors.white : Colors.black,
          fontSize: (text.fontHeight ?? 20).toDouble(),
          height: 1.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(maxWidth: text.maxWidth?.toDouble() ?? double.infinity);
    textPainter.paint(canvas, Offset(text.x.toDouble(), text.y.toDouble()));
  }

  void _drawTextBlock(Canvas canvas, ZplTextBlock textBlock) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: textBlock.text,
        style: const TextStyle(color: Colors.black, fontSize: 24, height: 1.2),
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
    final paint = Paint()
      ..color =
          const Color(0x4D00BCD4) // Colors.cyan with 30% opacity
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
        style: const TextStyle(color: Colors.black, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
