import 'dart:io';

import 'package:flutter/material.dart';

class DisplayTextScreen extends StatefulWidget {
  const DisplayTextScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  final String imagePath;

  @override
  State<DisplayTextScreen> createState() => _DisplayTextScreenState();
}

class _DisplayTextScreenState extends State<DisplayTextScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.file(File(widget.imagePath)),
      ),
    );
  }
}
