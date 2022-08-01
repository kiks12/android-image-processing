import 'dart:ui';
import 'dart:ui' as ui;

import 'package:android_image_processing/painters/coordinates_translator.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

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
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var object in objects) {
      final ParagraphBuilder builder = ParagraphBuilder(
        ParagraphStyle(
            textAlign: TextAlign.left,
            fontSize: 16,
            textDirection: TextDirection.ltr),
      );
      builder.pushStyle(ui.TextStyle(color: Colors.lightGreenAccent));

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
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
