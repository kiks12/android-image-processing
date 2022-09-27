import 'package:flutter/material.dart';

class ParagraphPainter extends CustomPainter {
  const ParagraphPainter({required this.text});

  final String text;

  @override
  void paint(Canvas canvas, Size size) {
    const textStyle =
        TextStyle(color: Colors.black, fontSize: 15, fontFamily: 'Poppins');
    final textSpan = TextSpan(
      text: text,
      style: textStyle,
    );
    final textPainter = TextPainter(
      textAlign: TextAlign.left,
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width - 50,
    );
    const offset = Offset(25, 0);
    textPainter.paint(canvas, offset);

    canvas.save();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
