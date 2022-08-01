import 'package:flutter/material.dart';

class RectanglePainter extends CustomPainter {
  const RectanglePainter({
    this.xPoint,
    this.yPoint,
    this.x,
    this.y,
    this.h,
    this.w,
  });

  final double? xPoint;
  final double? yPoint;

  final double? x;
  final double? y;
  final double? w;
  final double? h;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;

    if (xPoint == null && yPoint == null) return;

    final rect = Rect.fromPoints(Offset(x!, y!), Offset(w!, h!));

    canvas.drawRect(rect, paint);

    canvas.save();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
