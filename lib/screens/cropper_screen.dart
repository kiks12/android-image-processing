import 'dart:io';

import 'package:android_image_processing/screens/display_text_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageCropperScreen extends StatefulWidget {
  const ImageCropperScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  final String imagePath;

  @override
  State<ImageCropperScreen> createState() => _ImageCropperScreenState();
}

class _ImageCropperScreenState extends State<ImageCropperScreen> {
  CroppedFile? _croppedFile;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _body(),
    );
  }

  Widget _body() {
    // if (_croppedFile != null) {
    //   return Column(
    //     children: [
    //       _imageCard(_croppedFile!.path),
    //       ElevatedButton(
    //         onPressed: _cropImage,
    //         child: const Text('Crop'),
    //       ),
    //     ],
    //   );
    // }
    return Column(
      children: [
        _imageCard(widget.imagePath),
        ElevatedButton(
          onPressed: () async {
            final file = await _cropImage(File(widget.imagePath));
            print(file!.path);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: ((context) =>
                        DisplayTextScreen(imagePath: file.path))));
          },
          child: const Text('Crop'),
        ),
      ],
    );
  }

  Widget _imageCard(String path) {
    return Card(
      child: Image.file(File(path)),
    );
  }

  static Future<CroppedFile?> _cropImage(File image) async =>
      await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Image',
            initAspectRatio: CropAspectRatioPreset.original,
            showCropGrid: true,
            toolbarColor: Colors.transparent,
            dimmedLayerColor: const Color.fromARGB(133, 54, 54, 54),
            cropFrameColor: const Color.fromARGB(255, 219, 219, 219),
            cropGridColor: const Color.fromARGB(145, 255, 255, 255),
            cropGridStrokeWidth: 1,
            lockAspectRatio: false,
          )
        ],
      );
}
