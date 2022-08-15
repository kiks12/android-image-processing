import 'dart:io';
import 'dart:io' as io;

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
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

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

/* COLORS */
List<String> classes = [
  'Red',
  'Green',
  'Blue',
  'Yellow',
  'Orange',
  'Pink',
  'Purple',
  'Brown',
  'Grey',
  'Black',
  'White'
];
/* COLORS */

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
  PainterFeature _painterFeature = PainterFeature.ColorRecognition;
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

  /* Color Recognition Interpreter */
  Color _color = const Color.fromARGB(1, 1, 1, 1);
  tfl.Interpreter? _colorInterPreter;
  /* Color Recognition Interpreter */

  @override
  void initState() {
    super.initState();

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    _cameraController.lockCaptureOrientation();

    _initializeTts();
    _initializeCameraController();
    _initializeColorInterpreter();
  }

  @override
  void dispose() {
    super.dispose();
    _cameraController.dispose();
  }

  void _initializeColorInterpreter() async {
    _colorInterPreter = await tfl.Interpreter.fromAsset(
        'ml/color_recognition_model_8.0.3.tflite');
    setState(() {});
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
  _processCameraImage(CameraImage image, dynamic onImage) {
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
    if (imageRotation == null) return null;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw);
    if (inputImageFormat == null) return null;

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
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    onImage(inputImage);
  }

  void _imageStreamCallback(CameraImage image) async {
    if (_painterFeature == PainterFeature.ObjectDetection) {
      _processCameraImage(image, _objectDetectionProcessImage);
    }
    if (_painterFeature == PainterFeature.ColorRecognition) {
      if (localOffsetX == null && localOffsetY == null) return;
      final rgb = [];
      final xOffset = ((image.width * localOffsetX!)).floor();
      final yOffset = (image.height - (image.height * localOffsetY!)).floor();

      final yRowStride = image.planes[0].bytesPerRow;
      final uvRowStride = image.planes[1].bytesPerRow;
      final uvPixelStride = image.planes[1].bytesPerPixel!;

      final uvIndexCenter = (uvPixelStride * (xOffset / 2).floor()) +
          (uvRowStride * (yOffset / 2).floor());
      final yIndexCenter = yRowStride * yOffset + xOffset;

      final ypc = image.planes[0].bytes[yIndexCenter];
      final upc = image.planes[1].bytes[uvIndexCenter];
      final vpc = image.planes[2].bytes[uvIndexCenter];

      rgb.add(yuv2rgb(ypc, upc, vpc));

      // print(rgb);

      List<List<double>> output = [
        [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
      ];

      _colorInterPreter ??= await tfl.Interpreter.fromAsset(
          'ml/color_recognition_model_8.0.2.tflite');

      _colorInterPreter!.run(rgb, output);

      String prediction = '';
      for (int i = 0; i < output.length; i++) {
        final max = output[i]
            .reduce((value, element) => value > element ? value : element);
        prediction = classes[output[i].indexOf(max)];
      }

      _color = Color.fromARGB(
        255,
        rgb[0][0].floor(),
        rgb[0][1].floor(),
        rgb[0][2].floor(),
      );

      // print(output);
      // print(prediction);
      flutterTts.speak('The color is $prediction');
      setState(() {});
    }
  }

  static yuv2rgb(int y, int u, int v) {
    // Convert yuv pixel to rgb
    int r = (y + v * 1436 / 1024 - 179).round().clamp(0, 255);
    int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91)
        .round()
        .clamp(0, 255);
    int b = (y + u * 1814 / 1024 - 227).round().clamp(0, 255);

    return [
      double.parse(r.toString()),
      double.parse(g.toString()),
      double.parse(b.toString())
    ];
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
    _customPaint2 = null;
    _painterFeature = feature;
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

    localOffsetX = details.localPosition.dx;
    localOffsetY = details.localPosition.dy;
    x = localOffsetX! - 15;
    y = localOffsetY! - 15;
    w = localOffsetX! + 15;
    h = localOffsetY! + 15;
  }

  void _onScreenClickProxy(
      TapDownDetails details, BoxConstraints constraints, Offset offset) async {
    localOffsetX = offset.dy;
    localOffsetY = offset.dx;
    _onScreenClick(details);
    setState(() {});
  }

  CustomPaint _rectanglePainter() {
    return CustomPaint(
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
      _customPaint = _rectanglePainter();
    }

    return _customPaint;
  }

  CustomPaint? _painterTwo() {
    if (_painterFeature == PainterFeature.ObjectDetection) {
      _initializeDetector(DetectionMode.stream);
      _startLiveFeed(_imageStreamCallback);
    }

    if (_painterFeature == PainterFeature.ColorRecognition) {
      _customPaint2 = null;
      _startLiveFeed(_imageStreamCallback);
    }

    if (_painterFeature == PainterFeature.TextRecognition) {
      _customPaint2 = null;
      _stopLiveFeed();
    }

    return _customPaint2;
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
                        onScreenClick: _onScreenClickProxy,
                        controller: _cameraController,
                        customPaint: _painter(),
                        customPaint2: _painterTwo(),
                        painterFeature: _painterFeature,
                      ),
                Positioned.fromRect(
                  rect: localOffsetX != null && localOffsetY != null
                      ? Rect.fromPoints(Offset(x!, y!), Offset(w!, h!))
                      : Rect.zero,
                  child: Container(
                    decoration: BoxDecoration(
                        color: _color,
                        border: Border.all(
                          width: 1.0,
                          color: _color,
                          style: BorderStyle.solid,
                        )),
                  ),
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
