import 'package:android_image_processing/camera/camera_view.dart';
import 'package:android_image_processing/painters/object_detector_painter.dart';
import 'package:android_image_processing/painters/rectangle_painter.dart';
import 'package:android_image_processing/widgets/painter_controller.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'dart:io' as io;

List<CameraDescription> cameras = [];

enum PainterFeature { ObjectDetection, ColorRecognition, TextRecognition }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Android Image Processing',
      theme: ThemeData(
        primarySwatch: Colors.pink,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /* Custom Paint Variables */
  CustomPaint? _customPaint;
  CustomPaint? _customPaint2;
  PainterFeature _painterFeature = PainterFeature.ColorRecognition;
  /* */

  /* Screen Click Coordinates Variables */
  double? xPoint;
  double? yPoint;

  double? x;
  double? y;
  double? w;
  double? h;
  /*  */

  /* Object Detector Variables */
  ObjectDetector? _objectDetector;
  bool _canProcess = false;
  bool _isBusy = false;
  /*  */

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setPainterFeature(PainterFeature feature) {
    _painterFeature = feature;
    if (feature == PainterFeature.ObjectDetection) {
      _initializeDetector(DetectionMode.stream);
    }
    if (feature == PainterFeature.ColorRecognition) {
      _customPaint2 = null;
    }
    if (feature == PainterFeature.TextRecognition) {
      _customPaint2 = null;
    }
    setState(() {});
  }

  void _onScreenClick(TapDownDetails details) {
    xPoint = details.globalPosition.dx;
    yPoint = details.globalPosition.dy;
    x = xPoint! - 30;
    y = yPoint! - 30;
    w = xPoint! + 30;
    h = yPoint! + 30;
    setState(() {});
  }

  CustomPaint? _painter() {
    if (_painterFeature == PainterFeature.ObjectDetection) {
      _customPaint = CustomPaint(
        painter: RectanglePainter(
          xPoint: xPoint,
          yPoint: yPoint,
          x: x,
          y: y,
          w: w,
          h: h,
        ),
      );
    }
    if (_painterFeature == PainterFeature.ColorRecognition) {
      _customPaint = const CustomPaint();
      // _painterFeature = // whatever it is.
    }
    return _customPaint;
  }

  Widget _header() {
    late String text;

    if (_painterFeature == PainterFeature.ObjectDetection) {
      text = 'Object Recognition';
    }
    if (_painterFeature == PainterFeature.ColorRecognition) {
      text = 'Color Recognition';
    }
    if (_painterFeature == PainterFeature.TextRecognition) {
      text = 'Text Recognition';
    }

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
              const Padding(
                padding: EdgeInsets.only(left: 20),
                child: Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GestureDetector(
            onTapDown: _onScreenClick,
            onTapUp: ((details) {
              xPoint = null;
              yPoint = null;
            }),
            child: CameraView(
              customPaint2: _customPaint2,
              customPaint: _painter(),
              painterFeature: _painterFeature,
              onImage: ((inputImage) {
                if (_painterFeature == PainterFeature.ObjectDetection) {
                  objectDetectionProcessImage(inputImage);
                }
              }),
            ),
          ),
          _header(),
          PainterController(
            painterFeature: _painterFeature,
            setPainterFeature: _setPainterFeature,
          ),
        ],
      ),
    );
  }

  Future<void> objectDetectionProcessImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {});
    final objects = await _objectDetector!.processImage(inputImage);
    final painter = ObjectDetectorPainter(objects, x: x, y: y, w: w, h: h);
    _customPaint2 = CustomPaint(painter: painter);
    _isBusy = false;
    if (mounted) {
      setState(() {});
    }
  }

  void _initializeDetector(DetectionMode mode) async {
    const path = 'assets/ml/object_labeler.tflite';
    final modelPath = await _getModel(path);
    final options = LocalObjectDetectorOptions(
      mode: mode,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);

    _canProcess = true;

    setState(() {});
  }

  Future<String> _getModel(String assetPath) async {
    if (io.Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final pathDir =
        '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await io.Directory(path.dirname(pathDir)).create(recursive: true);
    final file = io.File(pathDir);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }
}
