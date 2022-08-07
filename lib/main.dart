import 'dart:io';
import 'dart:io' as io;
// import 'dart:math' as math;

import 'package:android_image_processing/camera/camera_view.dart';
import 'package:android_image_processing/painters/object_detector_painter.dart';
import 'package:android_image_processing/painters/rectangle_painter.dart';
import 'package:android_image_processing/widgets/main_header.dart';
import 'package:android_image_processing/widgets/painter_controller.dart';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

List<CameraDescription> cameras = [];

/* Text to Speech variables */
late FlutterTts flutterTts;
String? language;
String? engine;
double volume = 0.5;
double pitch = 1.0;
double rate = 0.5;
bool isCurrentLanguageInstalled = false;

bool get isIOS => !kIsWeb && Platform.isIOS;
bool get isAndroid => !kIsWeb && Platform.isAndroid;
bool get isWindows => !kIsWeb && Platform.isWindows;
bool get isWeb => kIsWeb;
/* */

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
  /* UI Variables */
  bool _isLoading = false;
  /* UI Variables */

  /* Custom Paint Variables */
  CustomPaint? _customPaint;
  CustomPaint? _customPaint2;
  PainterFeature _painterFeature = PainterFeature.ObjectDetection;
  /* */

  /* Screen Click Coordinates Variables */
  double? localOffsetX;
  double? localOffsetY;
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

  /* Camera Controller Variables */
  late CameraController _cameraController;
  int _cameraIndex = 0;
  CameraLensDirection _initialDirection = CameraLensDirection.back;
  double _zoomLevel = 0.0, _minZoomLevel = 0.0, _maxZoomLevel = 0.0;
  bool _changingCameraLens = false;
  /*  */

  @override
  void initState() {
    super.initState();

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _initializeTts();
    _initializeCameraController();
  }

  @override
  void dispose() {
    super.dispose();
    _cameraController.dispose();
  }

  /* CAMERA CONTROLLER FUNCTIONS */
  void _initializeCameraController() {
    if (cameras.any(
      (element) =>
          element.lensDirection == _initialDirection &&
          element.sensorOrientation == 90,
    )) {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere((element) =>
            element.lensDirection == _initialDirection &&
            element.sensorOrientation == 90),
      );
    } else {
      _cameraIndex = cameras.indexOf(
        cameras.firstWhere(
          (element) => element.lensDirection == _initialDirection,
        ),
      );
    }

    _cameraController.initialize().then((value) {
      if (!mounted) return;

      _cameraController.getMinZoomLevel().then((value) {
        _zoomLevel = value;
        _minZoomLevel = value;
      });

      _cameraController
          .getMaxZoomLevel()
          .then((value) => _maxZoomLevel = value);

      if (_painterFeature != PainterFeature.TextRecognition) {
        _startLiveFeed(_imageStreamCallback);
      }

      setState(() {});
    });
  }

  void _startLiveFeed(void Function(CameraImage image) func) async {
    _cameraController.startImageStream(func);
  }

  void _stopLiveFeed() async {
    await _cameraController.stopImageStream();
  }

  /* 
  This Function Converts the CameraImage to an InputImage - usable for 
  object detection and color recognition

  RETURNS : InputImage
  */
  Future<InputImage> _processCameraImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final camera = cameras[_cameraIndex];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);
    // if (imageRotation == null) return Future.value(null);

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    // if (inputImageFormat == null) return Future.value(null);

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation!,
      inputImageFormat: inputImageFormat!,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    return inputImage;
  }

  void _imageStreamCallback(CameraImage image) async {
    if (_painterFeature == PainterFeature.ObjectDetection) {
      final inputImage = await _processCameraImage(image);
      await _objectDetectionProcessImage(inputImage);
    }
    if (_painterFeature == PainterFeature.ColorRecognition) {
      setState(() {});
    }
  }
  /* CAMERA CONTROLLER FUNCTIONS */

  /* TEXT TO SPEECH FUNCTIONS */
  Future _setAwaitOptions() async {
    await flutterTts.awaitSpeakCompletion(true);
  }

  Future _getDefaultEngine() async {
    var engine = await flutterTts.getDefaultEngine;
    if (engine != null) {
      // print(engine);
    }
  }

  void _initializeTts() {
    flutterTts = FlutterTts();
    _setAwaitOptions();
    if (isAndroid) {
      _getDefaultEngine();
    }
  }
  /* TEXT TO SPEECH FUNCTIONS */

  /* PAINTER MENU CONTROLLER FUNCTIONS */
  void _setPainterFeature(PainterFeature feature) {
    localOffsetX = null;
    localOffsetY = null;
    x = null;
    y = null;
    w = null;
    h = null;
    _customPaint = null;
    _painterFeature = feature;

    if (feature == PainterFeature.ObjectDetection) {
      _startLiveFeed(_imageStreamCallback);
      _initializeDetector(DetectionMode.stream);
    }

    if (feature == PainterFeature.ColorRecognition) {
      _startLiveFeed(_imageStreamCallback);
      _customPaint2 = null;
    }

    if (feature == PainterFeature.TextRecognition) {
      _stopLiveFeed();
      _customPaint2 = null;
    }

    setState(() {});
  }

  void _onScreenClick(TapDownDetails details) {
    if (x != null && y != null && w != null && h != null) {
      x = null;
      y = null;
      w = null;
      h = null;
      localOffsetX = null;
      localOffsetY = null;
    }

    localOffsetX = details.globalPosition.dx;
    localOffsetY = details.globalPosition.dy;
    x = localOffsetX! - 30;
    y = localOffsetY! - 30;
    w = localOffsetX! + 30;
    h = localOffsetY! + 30;

    setState(() {});
  }

  void _rectanglePainterSetter() {
    _customPaint = CustomPaint(
      painter: RectanglePainter(
        xPoint: localOffsetX,
        yPoint: localOffsetY,
        x: x,
        y: y,
        w: w,
        h: h,
      ),
    );
  }

  CustomPaint? _painter() {
    if (_painterFeature == PainterFeature.ObjectDetection) {
      _rectanglePainterSetter();
      // can add another canvas using customPainter2
    }

    if (_painterFeature == PainterFeature.ColorRecognition) {
      _rectanglePainterSetter();
      // can add another canvas using customPainter2
    }

    setState(() {});
    return _customPaint;
  }
  /* PAINTER MENU CONTROLLER FUNCTIONS */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GestureDetector(
            onTapDown: _onScreenClick,
            child: Stack(
              children: [
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : CameraView(
                        controller: _cameraController,
                        customPaint: _painter(),
                        customPaint2: _customPaint2,
                        painterFeature: _painterFeature,
                      ),
              ],
            ),
          ),
          MainHeader(painterFeature: _painterFeature),
          PainterController(
            painterFeature: _painterFeature,
            setPainterFeature: _setPainterFeature,
          ),
        ],
      ),
    );
  }

  /* OBJECT DETECTOR FUNCTIONS */
  Future<void> _objectDetectionProcessImage(InputImage inputImage) async {
    if (!_canProcess) return;
    if (_isBusy) return;
    _isBusy = true;
    setState(() {});
    final objects = await _objectDetector!.processImage(inputImage);
    final painter = ObjectDetectorPainter(
      objects,
      inputImage.inputImageData!.size,
      inputImage.inputImageData!.imageRotation,
      x,
      y,
      w,
      h,
    );
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
  /* OBJECT DETECTOR FUNCTIONS */

}
