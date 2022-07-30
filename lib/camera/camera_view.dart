import 'dart:io';

import 'package:android_image_processing/screens/cropper_screen.dart';
import 'package:android_image_processing/screens/display_text_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../main.dart';

enum ScreenMode { liveFeed, gallery }

class CameraView extends StatefulWidget {
  const CameraView({
    Key? key,
    required this.customPaint,
    this.text,
    required this.onImage,
    this.onScreenModeChanged,
    required this.painterFeature,
    this.initialDirection = CameraLensDirection.back,
  }) : super(key: key);

  final CustomPaint? customPaint;
  final String? text;
  final Function(InputImage inputImage) onImage;
  final Function(ScreenMode mode)? onScreenModeChanged;
  final CameraLensDirection initialDirection;
  final PainterFeature painterFeature;

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  // Camera Preview Variables
  ScreenMode _mode = ScreenMode.liveFeed;
  CameraController? _controller;
  // File? _image;
  // String? _path;
  // ImagePicker? _imagePicker;
  int _cameraIndex = 0;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  // final bool _allowPicker = true;
  bool _changingCameraLens = false;

  // Image Cropper Variables
  CroppedFile? _croppedFile;

  @override
  void initState() {
    super.initState();

    // _imagePicker = ImagePicker();

    if (cameras.any(
      (element) =>
          element.lensDirection == widget.initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
            element.lensDirection == widget.initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere(
          (element) => element.lensDirection == widget.initialDirection,
        ),
      );
    }

    _startLiveFeed();
  }

  @override
  void dispose() {
    _stopLiveFeed();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(widget.title),
      //   actions: [
      //     if (_allowPicker)
      //       Padding(
      //         padding: const EdgeInsets.only(right: 20.0),
      //         child: GestureDetector(
      //           onTap: _switchScreenMode,
      //           child: Icon(
      //             _mode == ScreenMode.liveFeed
      //                 ? Icons.photo_library_outlined
      //                 : (Platform.isIOS
      //                     ? Icons.camera_alt_outlined
      //                     : Icons.camera),
      //           ),
      //         ),
      //       ),
      //   ],
      // ),
      body: _liveFeedBody(),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Future<void> _cropImage(String path) async {
  //   ImageCropper().cropImage(
  //     sourcePath: path,
  //     compressFormat: ImageCompressFormat.jpg,
  //     compressQuality: 10,
  //     uiSettings: [
  //       AndroidUiSettings(
  //         toolbarTitle: 'Crop Image',
  //         initAspectRatio: CropAspectRatioPreset.original,
  //         showCropGrid: true,
  //         toolbarColor: Colors.transparent,
  //         dimmedLayerColor: const Color.fromARGB(133, 54, 54, 54),
  //         cropFrameColor: Colors.white,
  //         cropGridColor: const Color.fromARGB(145, 255, 255, 255),
  //         cropGridStrokeWidth: 1,
  //         lockAspectRatio: false,
  //       )
  //     ],
  //   ).then(
  //     (value) => Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: ((context) => DisplayTextScreen(imagePath: value!.path)),
  //       ),
  //     ),
  //   );
  // }

  Future<XFile?> _capturePicture() async => await _controller?.takePicture();

  Widget _circleButton() {
    if (widget.painterFeature == PainterFeature.TextRecognition) {
      return GestureDetector(
        onTap: () async {
          _capturePicture().then((value) => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: ((context) =>
                      ImageCropperScreen(imagePath: value!.path)))));
          // await _cropImage(file!.path);
          // Navigator.push(
          //     context,
          //     MaterialPageRoute(
          //         builder: ((context) =>
          //             DisplayTextScreen(imagePath: file!.path))));
        },
        child: const CircleAvatar(
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 38,
            backgroundColor: Colors.black87,
            child: CircleAvatar(
              radius: 34,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _switchLiveCamera,
      child: CircleAvatar(
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 38,
          backgroundColor: Colors.black87,
          child: CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            child: Icon(
              Platform.isIOS
                  ? Icons.flip_camera_ios_outlined
                  : Icons.flip_camera_android_outlined,
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  Widget? _floatingActionButton() {
    if (_mode == ScreenMode.gallery) return null;
    if (cameras.length == 1) return null;
    return SizedBox(
      height: 80.0,
      width: 80.0,
      child: _circleButton(),
    );
  }

  // Widget _body() {
  //   Widget body;
  //   if (_mode == ScreenMode.liveFeed) {
  //     body = _liveFeedBody();
  //   }
  //   // else {
  //   //   body = _galleryBody();
  //   // }
  //   return body;
  // }

  Widget _liveFeedBody() {
    if (_controller?.value.isInitialized == false) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * _controller!.value.aspectRatio;

    if (scale < 1) scale = (1 / scale);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Transform.scale(
            scale: scale,
            child: Center(
              child: _changingCameraLens
                  ? const Center(
                      child: Text('Changing camera lens'),
                    )
                  : CameraPreview(_controller!),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.25,
              width: MediaQuery.of(context).size.width,
              color: const Color.fromARGB(99, 0, 0, 0),
            ),
          ),
          if (widget.customPaint != null) widget.customPaint!,
          Positioned(
            bottom: 170,
            left: 50,
            right: 50,
            child: Slider(
              value: zoomLevel,
              min: minZoomLevel,
              max: maxZoomLevel,
              onChanged: (newSliderValue) {
                setState(() {
                  zoomLevel = newSliderValue;
                  _controller!.setZoomLevel(zoomLevel);
                });
              },
              divisions: (maxZoomLevel - 1).toInt() < 1
                  ? null
                  : (maxZoomLevel - 1).toInt(),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _galleryBody() {
  //   return ListView(shrinkWrap: true, children: [
  //     _image != null
  //         ? SizedBox(
  //             height: 400,
  //             width: 400,
  //             child: Stack(
  //               fit: StackFit.expand,
  //               children: <Widget>[
  //                 Image.file(_image!),
  //                 if (widget.customPaint != null) widget.customPaint!,
  //               ],
  //             ),
  //           )
  //         : const Icon(
  //             Icons.image,
  //             size: 200,
  //           ),
  //     Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 16),
  //       child: ElevatedButton(
  //         child: const Text('From Gallery'),
  //         onPressed: () => _getImage(ImageSource.gallery),
  //       ),
  //     ),
  //     Padding(
  //       padding: const EdgeInsets.symmetric(horizontal: 16),
  //       child: ElevatedButton(
  //         child: const Text('Take a picture'),
  //         onPressed: () => _getImage(ImageSource.camera),
  //       ),
  //     ),
  //     if (_image != null)
  //       Padding(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Text(
  //             '${_path == null ? '' : 'Image path: $_path'}\n\n${widget.text ?? ''}'),
  //       ),
  //   ]);
  // }

  // Future _getImage(ImageSource source) async {
  //   setState(() {
  //     _image = null;
  //     _path = null;
  //   });
  //   final pickedFile = await _imagePicker?.pickImage(source: source);
  //   if (pickedFile != null) {
  //     _processPickedFile(pickedFile);
  //   }
  //   setState(() {});
  // }

  // void _switchScreenMode() {
  //   _image = null;
  //   if (_mode == ScreenMode.liveFeed) {
  //     _mode = ScreenMode.gallery;
  //     _stopLiveFeed();
  //   } else {
  //     _mode = ScreenMode.liveFeed;
  //     _startLiveFeed();
  //   }
  //   if (widget.onScreenModeChanged != null) {
  //     widget.onScreenModeChanged!(_mode);
  //   }
  //   setState(() {});
  // }

  Future _startLiveFeed() async {
    final camera = cameras[_cameraIndex];
    _controller = CameraController(
      camera,
      ResolutionPreset.max,
    );
    _controller?.initialize().then((_) {
      if (!mounted) {
        return;
      }
      _controller?.getMinZoomLevel().then((value) {
        zoomLevel = value;
        minZoomLevel = value;
      });
      _controller?.getMaxZoomLevel().then((value) {
        maxZoomLevel = value;
      });
      // if (widget.paintFeature != PaintFeature.TextRecognition) {
      // _controller?.startImageStream(_processCameraImage);
      // }
      setState(() {});
    });
  }

  Future _stopLiveFeed() async {
    await _controller?.stopImageStream();
    await _controller?.dispose();
    _controller = null;
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % cameras.length;

    await _stopLiveFeed();
    await _startLiveFeed();
    setState(() => _changingCameraLens = false);
  }

  // Future _processPickedFile(XFile? pickedFile) async {
  //   final path = pickedFile?.path;
  //   if (path == null) {
  //     return;
  //   }
  //   setState(() {
  //     _image = File(path);
  //   });
  //   _path = path;
  //   final inputImage = InputImage.fromFilePath(path);
  //   widget.onImage(inputImage);
  // }

  // Future _processCameraImage(CameraImage image) async {
  //   final WriteBuffer allBytes = WriteBuffer();
  //   for (final Plane plane in image.planes) {
  //     allBytes.putUint8List(plane.bytes);
  //   }
  //   final bytes = allBytes.done().buffer.asUint8List();

  //   final Size imageSize =
  //       Size(image.width.toDouble(), image.height.toDouble());

  //   final camera = cameras[_cameraIndex];
  //   final imageRotation =
  //       InputImageRotationValue.fromRawValue(camera.sensorOrientation);
  //   if (imageRotation == null) return;

  //   final inputImageFormat =
  //       InputImageFormatValue.fromRawValue(image.format.raw);
  //   if (inputImageFormat == null) return;

  //   final planeData = image.planes.map(
  //     (Plane plane) {
  //       return InputImagePlaneMetadata(
  //         bytesPerRow: plane.bytesPerRow,
  //         height: plane.height,
  //         width: plane.width,
  //       );
  //     },
  //   ).toList();

  //   final inputImageData = InputImageData(
  //     size: imageSize,
  //     imageRotation: imageRotation,
  //     inputImageFormat: inputImageFormat,
  //     planeData: planeData,
  //   );

  //   final inputImage =
  //       InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

  //   widget.onImage(inputImage);
  // }
}
