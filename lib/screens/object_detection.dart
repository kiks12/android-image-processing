import 'package:android_image_processing/camera/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class ObjectDetectionScreen extends StatefulWidget {
  const ObjectDetectionScreen({Key? key}) : super(key: key);

  @override
  State<ObjectDetectionScreen> createState() => _ObjectDetectionScreenState();
}

class _ObjectDetectionScreenState extends State<ObjectDetectionScreen> {
  CustomPaint? _customPaint;

  @override
  Widget build(BuildContext context) {
    return CameraView(
      customPaint: _customPaint,
      onImage: (inputImage) {
        // processImage(inputImage);
      },
    );
  }

  // Future<void> processImage(InputImage inputImage) async {
  //   if (!_canProcess) return;
  //   if (_isBusy) return;
  //   _isBusy = true;
  //   setState(() {
  //     _text = '';
  //   });
  //   final objects = await _objectDetector.processImage(inputImage);
  //   if (inputImage.inputImageData?.size != null &&
  //       inputImage.inputImageData?.imageRotation != null) {
  //     final painter = ObjectDetectorPainter(
  //         objects,
  //         inputImage.inputImageData!.imageRotation,
  //         inputImage.inputImageData!.size);
  //     _customPaint = CustomPaint(painter: painter);
  //   } else {
  //     String text = 'Objects found: ${objects.length}\n\n';
  //     for (final object in objects) {
  //       text +=
  //           'Object:  trackingId: ${object.trackingId} - ${object.labels.map((e) => e.text)}\n\n';
  //     }
  //     _text = text;
  //     // TODO: set _customPaint to draw boundingRect on top of image
  //     _customPaint = null;
  //   }
  //   _isBusy = false;
  //   if (mounted) {
  //     setState(() {});
  //   }
  // }
}
