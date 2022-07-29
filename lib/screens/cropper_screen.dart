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
    _cropImage().then(
      (value) {
        setState(() {
          _croppedFile = value;
        });

        if (_croppedFile != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: ((context) => DisplayTextScreen(imagePath: value!.path)),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(),
    );
  }

  Future<CroppedFile?> _cropImage() async {
    return await ImageCropper().cropImage(
      sourcePath: widget.imagePath,
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 100,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          initAspectRatio: CropAspectRatioPreset.original,
          showCropGrid: true,
          toolbarColor: Colors.transparent,
          dimmedLayerColor: const Color.fromARGB(133, 54, 54, 54),
          cropFrameColor: Colors.white,
          cropGridColor: const Color.fromARGB(145, 255, 255, 255),
          cropGridStrokeWidth: 1,
          lockAspectRatio: false,
        )
      ],
    );
  }
}
