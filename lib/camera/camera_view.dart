import 'dart:io';
import 'package:android_image_processing/screens/display_text_screen.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'package:image_cropper/image_cropper.dart';

import '../main.dart';

enum ScreenMode { liveFeed, gallery }

class CameraView extends StatefulWidget {
  const CameraView({
    Key? key,
    required this.customPaint,
    required this.customPaint2,
    this.text,
    this.onScreenModeChanged,
    required this.painterFeature,
    required this.controller,
    required this.onScreenClick,
    required this.startLiveFeed,
  }) : super(key: key);

  final CustomPaint? customPaint;
  final CustomPaint? customPaint2;
  final String? text;
  final Function(ScreenMode mode)? onScreenModeChanged;
  final PainterFeature painterFeature;
  final CameraController controller;
  final void Function(
          TapDownDetails details, BoxConstraints constraints, Offset offset)
      onScreenClick;
  final void Function() startLiveFeed;

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  /* Camera Preview Variables */
  final ScreenMode _mode = ScreenMode.liveFeed;
  int _cameraIndex = 0;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  bool _changingCameraLens = false;
  /*    */

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _liveFeedBody(),
          if (widget.customPaint != null) widget.customPaint!,
        ],
      ),
      floatingActionButton: _floatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  /* IMAGE CROPPER */
  Future<CroppedFile?> _cropImage(String path) async {
    return await ImageCropper().cropImage(
      sourcePath: path,
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
          cropGridColor: const Color.fromARGB(100, 255, 255, 255),
          cropGridStrokeWidth: 1,
          lockAspectRatio: false,
        )
      ],
    );
  }

  Future<void> _capturePicture() async {
    if (!widget.controller.value.isInitialized) return;
    if (widget.controller.value.isTakingPicture) return;
    try {
      final picture = await widget.controller.takePicture();
      final croppedImage = await _cropImage(picture.path);
      if (croppedImage == null) return;
      Future.microtask(
        () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: ((context) =>
                DisplayTextScreen(imagePath: croppedImage.path)),
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  Widget _circleButton() {
    if (widget.painterFeature == PainterFeature.textRecognition) {
      return GestureDetector(
        onTap: _capturePicture,
        child: const CircleAvatar(
          backgroundColor: Colors.white,
          child: CircleAvatar(
            radius: 38,
            backgroundColor: Colors.black87,
            child: CircleAvatar(
              radius: 36,
              backgroundColor: Colors.white,
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
            radius: 36,
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
    if (cameras.length == 1) return null;
    return SizedBox(
      height: 80.0,
      width: 80.0,
      child: _circleButton(),
    );
  }

  void _onPreviewTapDown(TapDownDetails details, BoxConstraints constraints) {
    Offset offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    widget.onScreenClick(details, constraints, offset);
    widget.controller.setFocusPoint(offset);
    widget.controller.setExposurePoint(offset);
  }

  Widget _liveFeedBody() {
    if (widget.controller.value.isInitialized == false) {
      return Container();
    }

    final size = MediaQuery.of(context).size;
    var scale = size.aspectRatio * widget.controller.value.aspectRatio;

    if (scale < 1) scale = (1 / scale);

    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Transform.scale(
            scale: scale,
            alignment: Alignment.center,
            child: Center(
              child: _changingCameraLens
                  ? const Center(
                      child: Text('Changing camera lens'),
                    )
                  : CameraPreview(
                      widget.controller,
                      // key: widget.cameraKey,
                      child: LayoutBuilder(
                        builder: ((context, constraints) {
                          return GestureDetector(
                            onTapDown: (TapDownDetails details) =>
                                _onPreviewTapDown(details, constraints),
                          );
                        }),
                      ),
                    ),
            ),
          ),
          if (widget.painterFeature == PainterFeature.textRecognition)
            Positioned(
              right: 0,
              bottom: MediaQuery.of(context).size.height * 0.28,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Container(
                  height: 100,
                  width: 40,
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: _setCameraFlashMode,
                        icon: Icon(
                          widget.controller.value.flashMode == FlashMode.off
                              ? Icons.flash_off
                              : Icons.flash_on,
                          size: 25,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        onPressed: _switchLiveCamera,
                        icon: Icon(
                          Platform.isIOS
                              ? Icons.flip_camera_ios_outlined
                              : Icons.flip_camera_android_outlined,
                          size: 25,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            left: 0,
            child: Container(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height * 0.28,
                minWidth: MediaQuery.of(context).size.width,
              ),
              color: const Color.fromARGB(150, 0, 0, 0),
            ),
          ),
          if (widget.customPaint != null &&
              widget.painterFeature == PainterFeature.objectDetection)
            widget.customPaint!,
          if (widget.customPaint2 != null &&
              widget.painterFeature == PainterFeature.objectDetection)
            widget.customPaint2!,
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
                  widget.controller.setZoomLevel(newSliderValue);
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

  void _setCameraFlashMode() {
    if (widget.controller.value.flashMode == FlashMode.off) {
      widget.controller.setFlashMode(FlashMode.always);
      setState(() {});
      return;
    }
    widget.controller.setFlashMode(FlashMode.off);
    setState(() {});
  }

  Future _switchLiveCamera() async {
    setState(() => _changingCameraLens = true);
    _cameraIndex = (_cameraIndex + 1) % cameras.length;

    if (widget.painterFeature != PainterFeature.textRecognition) {
      await widget.controller.stopImageStream();
      widget.startLiveFeed();
    }

    if (widget.painterFeature == PainterFeature.textRecognition) {
      widget.controller.resumePreview();
    }
    setState(() => _changingCameraLens = false);
  }
}
