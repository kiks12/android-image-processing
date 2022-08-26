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

enum PainterFeature { objectDetection, colorRecognition, textRecognition }

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
  final bool _isLoading = false;
  /* UI Variables */

  /* Custom Paint Variables */
  CustomPaint? _customPaint;
  CustomPaint? _customPaint2;
  PainterFeature _painterFeature = PainterFeature.colorRecognition;
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
  final CameraLensDirection _initialDirection = CameraLensDirection.back;
  double zoomLevel = 0.0, minZoomLevel = 0.0, maxZoomLevel = 0.0;
  final bool _changingCameraLens = false;
  /*  */

  /* Color Recognition Interpreter */
  Color _color = const Color.fromARGB(1, 1, 1, 1);
  tfl.Interpreter? _colorInterPreter;
  final List<List<double>> _output = [
    [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  ];
  String predictedColor = '';
  bool _toSpeak = false;
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
    _cameraController.setFlashMode(FlashMode.off);

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
        'ml/color_recognition_model_8.0.4.tflite');
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
        zoomLevel = value;
        minZoomLevel = value;
      });

      _cameraController.getMaxZoomLevel().then((value) => maxZoomLevel = value);

      if (_painterFeature != PainterFeature.textRecognition) {
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

  void zoomCallback(newSliderValue) {
    // ignore: unnecessary_null_comparison
    if (_cameraController == null) return;
    _cameraController.setZoomLevel(newSliderValue);
    zoomLevel = newSliderValue;
    setState(() {});
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

  /* Color Recognition Functions */
  Map<String, int> _getPixelIndices(CameraImage image) {
    final xOffset = ((image.width * localOffsetX!)).floor();
    final yOffset = (image.height - (image.height * localOffsetY!)).floor();

    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel!;

    final uvIndex = (uvPixelStride * (xOffset / 2).floor()) +
        (uvRowStride * (yOffset / 2).floor());
    final yIndex = yRowStride * yOffset + xOffset;

    return {
      'y': yIndex,
      'uv': uvIndex,
    };
  }

  List<double> _getPixelRGB(CameraImage image, int yIndex, int uvIndex) {
    final y = image.planes[0].bytes[yIndex];
    final u = image.planes[1].bytes[uvIndex];
    final v = image.planes[2].bytes[uvIndex];

    return yuv2rgb(y, u, v);
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

  Future<String> _predictColor(List<List<double>> rgb) async {
    _colorInterPreter ??= await tfl.Interpreter.fromAsset(
      'ml/color_recognition_model.8.0.4.tflite',
    );
    _colorInterPreter!.run(rgb, _output);
    String prediction = '';
    for (int i = 0; i < _output.length; i++) {
      final max = _output[i]
          .reduce((value, element) => value > element ? value : element);
      prediction = classes[_output[i].indexOf(max)];
    }
    return prediction;
  }

  void _setBoundingBoxColor(List<double> rgb) {
    _color = Color.fromARGB(
      255,
      rgb[0].floor(),
      rgb[1].floor(),
      rgb[2].floor(),
    );
    setState(() {});
  }

  void _voiceOutPredictedColor(String color) async {
    await flutterTts.speak('The color is: $color');
    flutterTts.stop();
  }

  void _colorRecognitionProcess(CameraImage image) async {
    final pixelIndices = _getPixelIndices(image);
    final rgb = _getPixelRGB(
      image,
      pixelIndices['y'] as int,
      pixelIndices['uv'] as int,
    );
    _setBoundingBoxColor(rgb);
    String prediction = await _predictColor([rgb]);
    predictedColor = prediction;
    if (_toSpeak) {
      _voiceOutPredictedColor(prediction);
      _toSpeak = false;
    }

    setState(() {});
  }
  /* Color Recognition Functions */

  void _imageStreamCallback(CameraImage image) async {
    if (_painterFeature == PainterFeature.objectDetection) {
      _processCameraImage(image, _objectDetectionProcessImage);
    }
    if (_painterFeature == PainterFeature.colorRecognition) {
      if (localOffsetX == null && localOffsetY == null) return;
      _colorRecognitionProcess(image);
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
    _customPaint2 = null;
    _color = Colors.transparent;
    predictedColor = '';
    _painterFeature = feature;
    if (feature == PainterFeature.textRecognition) {
      _stopLiveFeed();
      _cameraController.resumePreview();
      if (mounted) {
        setState(() {});
      }
    }

    if (feature != PainterFeature.textRecognition) {
      _startLiveFeed(_imageStreamCallback);
      if (mounted) {
        setState(() {});
      }
    }

    if (mounted) {
      setState(() {});
    }
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
    _getClickBoundingBox(details);
    setState(() {});
  }

  void _getClickBoundingBox(TapDownDetails details) {
    x = details.globalPosition.dx - 15;
    y = details.globalPosition.dy - 15;
    w = details.globalPosition.dx + 15;
    h = details.globalPosition.dy + 15;
  }

  void _onCameraPreviewClick(
      TapDownDetails details, BoxConstraints constraints, Offset offset) async {
    localOffsetX = offset.dy;
    localOffsetY = offset.dx;
    _getClickBoundingBox(details);
    _toSpeak = true;
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
    _customPaint = null;
    if (_painterFeature == PainterFeature.objectDetection) {
      _customPaint = _rectanglePainter();
    }

    return _customPaint;
  }

  CustomPaint? _painterTwo() {
    if (_painterFeature == PainterFeature.objectDetection) {
      _initializeDetector(DetectionMode.stream);
    }

    return _customPaint2;
  }
  /* PAINTER MENU CONTROLLER FUNCTIONS */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _painterFeature == PainterFeature.objectDetection
              ? GestureDetector(
                  onTapDown: _onScreenClick,
                  child: Stack(
                    children: [
                      CameraView(
                        startLiveFeed: () =>
                            _startLiveFeed(_imageStreamCallback),
                        onScreenClick: _onCameraPreviewClick,
                        controller: _cameraController,
                        minZoomLevel: minZoomLevel,
                        maxZoomLevel: maxZoomLevel,
                        zoomLevel: zoomLevel,
                        zoomCallback: zoomCallback,
                        customPaint: _painter(),
                        customPaint2: _painterTwo(),
                        painterFeature: _painterFeature,
                      ),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    CameraView(
                      startLiveFeed: () => _startLiveFeed(_imageStreamCallback),
                      onScreenClick: _onCameraPreviewClick,
                      controller: _cameraController,
                      minZoomLevel: minZoomLevel,
                      maxZoomLevel: maxZoomLevel,
                      zoomLevel: zoomLevel,
                      zoomCallback: zoomCallback,
                      customPaint: _painter(),
                      customPaint2: _painterTwo(),
                      painterFeature: _painterFeature,
                    ),
                    if (localOffsetX != null && localOffsetY != null)
                      Positioned.fromRect(
                        rect: localOffsetX != null && localOffsetY != null
                            ? Rect.fromPoints(
                                Offset(x! - 7, y! - 7),
                                Offset(w! + 7, h! + 7),
                              )
                            : Rect.zero,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: _color,
                            border: Border.all(
                              width: 2,
                              color: Color.fromARGB(
                                _color.alpha,
                                _color.red + 20,
                                _color.green + 20,
                                _color.blue + 20,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
          MainHeader(painterFeature: _painterFeature),
          PainterController(
            painterFeature: _painterFeature,
            setPainterFeature: _setPainterFeature,
          ),
          if (predictedColor != '' &&
              _painterFeature == PainterFeature.colorRecognition)
            Positioned(
              top: 75,
              left: 10,
              right: 10,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                padding: const EdgeInsets.symmetric(vertical: 5),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: _color,
                  border: Border.all(
                    width: 2,
                    color: Color.fromARGB(
                      _color.alpha,
                      _color.red + 20,
                      _color.green + 20,
                      _color.blue + 20,
                    ),
                  ),
                ),
                child: Text(
                  predictedColor,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: predictedColor != 'White' || predictedColor != 'Grey'
                        ? Colors.white
                        : Colors.black,
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
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
