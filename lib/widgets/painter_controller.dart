import 'package:android_image_processing/main.dart';
import 'package:flutter/material.dart';

class PainterController extends StatefulWidget {
  const PainterController({
    Key? key,
    required this.setPainterFeature,
    required this.painterFeature,
  }) : super(key: key);

  final void Function(PainterFeature) setPainterFeature;
  final PainterFeature painterFeature;

  @override
  State<PainterController> createState() => PainterControllerState();
}

class PainterControllerState extends State<PainterController> {
  Widget _container(String text, PainterFeature feature) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: widget.painterFeature == feature
            ? [
                const BoxShadow(
                  color: Color.fromARGB(255, 73, 73, 73),
                  blurRadius: 7,
                  spreadRadius: 2,
                  offset: Offset(0.0, 5.0),
                ),
              ]
            : [
                const BoxShadow(color: Colors.transparent),
              ],
        color: widget.painterFeature == feature
            ? Colors.white
            : Colors.transparent,
        border: Border.all(color: Colors.white, width: 0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: widget.painterFeature == feature ? Colors.pink : Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 115,
      right: 0,
      left: 0,
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  widget.setPainterFeature(PainterFeature.ObjectDetection),
              child: _container(
                  'Object Recognition', PainterFeature.ObjectDetection),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  widget.setPainterFeature(PainterFeature.ColorRecognition),
              child: _container(
                  'Color Recognition', PainterFeature.ColorRecognition),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  widget.setPainterFeature(PainterFeature.TextRecognition),
              child: _container(
                  'Text Recognition', PainterFeature.TextRecognition),
            ),
          ),
        ],
      ),
    );
  }
}
