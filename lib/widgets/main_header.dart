import 'dart:io';

import 'package:android_image_processing/main.dart';
import 'package:flutter/material.dart';

class MainHeader extends StatefulWidget {
  const MainHeader({
    Key? key,
    required this.painterFeature,
    this.isMain = true,
  }) : super(key: key);

  final PainterFeature painterFeature;
  final bool isMain;

  @override
  State<MainHeader> createState() => _MainHeaderState();
}

class _MainHeaderState extends State<MainHeader> {
  String headerText() {
    String text = '';
    if (widget.painterFeature == PainterFeature.objectDetection) {
      text = 'Object Recognition';
    }
    if (widget.painterFeature == PainterFeature.colorRecognition) {
      text = 'Color Recognition';
    }
    if (widget.painterFeature == PainterFeature.textRecognition) {
      text = 'Text Recognition';
    }
    return text;
  }

  void exitApp() {
    exit(0);
  }

  void goBackToPreviousScreen() {
    Navigator.of(context).pop();
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
                  onTap: widget.isMain ? exitApp : goBackToPreviousScreen,
                  child: Icon(
                    Icons.arrow_back_ios,
                    color: widget.isMain ? Colors.white : Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  headerText(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.isMain ? Colors.white : Colors.black,
                    fontSize: 21.5,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Icon(
                  Icons.more_vert_outlined,
                  color: widget.isMain ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
