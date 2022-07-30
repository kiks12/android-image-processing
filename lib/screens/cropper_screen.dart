import 'package:flutter/material.dart';

class ImageCropperScreen extends StatefulWidget {
  const ImageCropperScreen({Key? key}) : super(key: key);

  @override
  State<ImageCropperScreen> createState() => _ImageCropperScreenState();
}

class _ImageCropperScreenState extends State<ImageCropperScreen> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Container(),
      ),
    );
  }
}
