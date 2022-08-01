import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class ObjectDetectorPainter extends CustomPainter {
  const ObjectDetectorPainter(
    this.objects, {
    this.x,
    this.h,
    this.w,
    this.y,
  });

  final List<DetectedObject> objects;
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
      final box = object.boundingBox;
      final rect = Rect.fromPoints(
        Offset(box.topLeft.dx, box.topLeft.dy),
        Offset(box.bottomRight.dx, box.bottomRight.dy),
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
