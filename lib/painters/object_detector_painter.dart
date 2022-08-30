import 'dart:ui';
import 'dart:ui' as ui;

import 'package:android_image_processing/main.dart';
import 'package:android_image_processing/painters/coordinates_translator.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

String lastObject = '';
double lastX = 0.0;
double lastY = 0.0;
double lastW = 0.0;
double lastH = 0.0;

class ObjectDetectorPainter extends CustomPainter {
  const ObjectDetectorPainter(
    this.objects,
    this.absoluteImageSize,
    this.rotation,
    this.x,
    this.y,
    this.w,
    this.h,
  );

  final List<DetectedObject> objects;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final double? x;
  final double? y;
  final double? w;
  final double? h;

  @override
  void paint(Canvas canvas, Size size) async {
    final paint = Paint()
      ..color = Colors.lightGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var object in objects) {
      final ParagraphBuilder builder = ParagraphBuilder(
        ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: 16,
            textDirection: TextDirection.ltr),
      );
      builder.pushStyle(
        ui.TextStyle(
          color: Colors.lightGreen,
          fontFamily: 'Poppins',
        ),
      );

      double confidence = 0.0;
      String text = '';
      for (final Label label in object.labels) {
        if (label.confidence > confidence) {
          confidence = label.confidence;
          text = label.text;
        }
      }
      builder.addText('$text $confidence');

      builder.pop();

      final left = translateX(
        object.boundingBox.left,
        rotation,
        size,
        absoluteImageSize,
      );
      final right = translateX(
        object.boundingBox.right,
        rotation,
        size,
        absoluteImageSize,
      );
      final top = translateY(
        object.boundingBox.top,
        rotation,
        size,
        absoluteImageSize,
      );
      final bottom = translateY(
        object.boundingBox.bottom,
        rotation,
        size,
        absoluteImageSize,
      );

      if (left > x! || right < w! || top > y! || bottom < h!) continue;

      final rect = Rect.fromLTRB(left, top, right, bottom);
      canvas.drawRect(rect, paint);

      canvas.drawParagraph(
        builder.build()
          ..layout(ParagraphConstraints(
            width: right - left,
          )),
        Offset(left, top),
      );

      if (text.isEmpty) {
        await flutterTts.speak('Object is unidentifiable');
        return;
      }

      if (lastObject == text &&
          lastX == x &&
          lastY == y &&
          lastW == w &&
          lastH == h) return;
      await flutterTts.speak('The object is $text');

      lastObject = text;
      lastX = x!;
      lastY = y!;
      lastW = w!;
      lastH = h!;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
