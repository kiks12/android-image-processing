import 'dart:io';

import 'package:android_image_processing/main.dart';
import 'package:flutter/material.dart';

class MainHeader extends StatefulWidget {
  const MainHeader({
    Key? key,
    required this.painterFeature,
  }) : super(key: key);

  final PainterFeature painterFeature;

  @override
  State<MainHeader> createState() => _MainHeaderState();
}

class _MainHeaderState extends State<MainHeader> {
  String _text() {
    String text = '';
    if (widget.painterFeature == PainterFeature.ObjectDetection) {
      text = 'Object Recognition';
    }
    if (widget.painterFeature == PainterFeature.ColorRecognition) {
      text = 'Color Recognition';
    }
    if (widget.painterFeature == PainterFeature.TextRecognition) {
      text = 'Text Recognition';
    }
    return text;
  }

  void _exitApp() {
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      right: 0,
      left: 0,
      child: SafeArea(
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.06,
          color: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 20),
                child: GestureDetector(
                  onTap: _exitApp,
                  child: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _text(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21.5,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 20),
                child: Icon(
                  Icons.more_vert_outlined,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
