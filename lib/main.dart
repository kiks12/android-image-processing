import 'dart:io';
import 'dart:math' as math;

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
import 'package:palette_generator/palette_generator.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'dart:io' as io;

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

  /* Camera Controller Variables */
  late CameraController _cameraController;
  /*  */

  /* Palette Generator Variables */
  Rect? region;
  PaletteGenerator? paletteGenerator;
  String text = '';
  /*  */

  @override
  void initState() {
    super.initState();

    _cameraController = CameraController(
      cameras[0],
      ResolutionPreset.max,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    initTts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /* PALETTE GENERATOR CODES */
  Future<void> _updatePaletteGenerator(Rect? newRegion, dynamic image) async {
    paletteGenerator = await PaletteGenerator.fromImage(
      image,
      region: newRegion!,
      maximumColorCount: 20,
    );
    // paletteGenerator = await PaletteGenerator.fromImage(
    //   image,
    //   region: newRegion!,
    //   maximumColorCount: 20,
    // );
    setState(() {});
  }
  /* PALETTE GENERATOR CODES */

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

  initTts() {
    flutterTts = FlutterTts();

    _setAwaitOptions();

    if (isAndroid) {
      _getDefaultEngine();
    }
  }
  /* TEXT TO SPEECH FUNCTIONS */

  /* PAINTER MENU CONTROLLER FUNCTIONS */
  void _setPainterFeature(PainterFeature feature) {
    xPoint = null;
    yPoint = null;
    x = null;
    y = null;
    w = null;
    h = null;
    _customPaint = null;
    _painterFeature = feature;
    if (feature == PainterFeature.ObjectDetection) {
      _initializeDetector(DetectionMode.stream);
    }
    if (feature == PainterFeature.ColorRecognition) {
      _cameraController.stopImageStream();
      _cameraController.startImageStream((image) async {
        final WriteBuffer allBytes = WriteBuffer();
        for (final Plane plane in image.planes) {
          allBytes.putUint8List(plane.bytes);
        }
        final bytes = allBytes.done().buffer.asUint8List();

        final Size imageSize =
            Size(image.width.toDouble(), image.height.toDouble());

        final inputImageFormat =
            InputImageFormatValue.fromRawValue(image.format.raw);
        if (inputImageFormat == null) return;

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
          imageRotation: InputImageRotation.rotation0deg,
          inputImageFormat: inputImageFormat,
          planeData: planeData,
        );

        final inputImage =
            InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

        Rect newRegion = Rect.fromPoints(Offset(x!, y!), Offset(w!, h!));
        await _updatePaletteGenerator(
            newRegion, Image.file(File(inputImage.filePath!)));
        text = inputImage.filePath!;
        setState(() {});
      });
      _customPaint2 = null;
    }
    if (feature == PainterFeature.TextRecognition) {
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
      xPoint = null;
      yPoint = null;
    }

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
      // can add another canvas using customPainter2
    }

    if (_painterFeature == PainterFeature.ColorRecognition) {
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
      // can add another canvas using customPainter2
    }

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
                CameraView(
                  controller: _cameraController,
                  customPaint: _painter(),
                  customPaint2: _customPaint2,
                  painterFeature: _painterFeature,
                  onImage: ((inputImage) async {
                    if (_painterFeature == PainterFeature.ObjectDetection) {
                      objectDetectionProcessImage(inputImage);
                    }
                    if (_painterFeature == PainterFeature.ColorRecognition) {
                      // Image image = Image.file(
                      //   File(inputImage.filePath!),
                      // );
                      // Rect newRegion =
                      //     Rect.fromPoints(Offset(x!, y!), Offset(w!, h!));
                      // await _updatePaletteGenerator(
                      //   newRegion,
                      //   image,
                      // );
                      // region = newRegion;
                      // text = inputImage.filePath!;
                      // setState(() {});
                    }
                  }),
                ),
              ],
            ),
          ),
          MainHeader(painterFeature: _painterFeature),
          Positioned(
            bottom: 300,
            left: 50,
            right: 50,
            child: Center(child: Text(text)),
          ),
          // Positioned(
          //   bottom: 300,
          //   left: 40,
          //   right: 40,
          //   child: PaletteSwatches(
          //     generator: paletteGenerator,
          //   ),
          // ),
          PainterController(
            painterFeature: _painterFeature,
            setPainterFeature: _setPainterFeature,
          ),
        ],
      ),
    );
  }

  /* OBJECT DETECTOR FUNCTIONS */

  Future<void> objectDetectionProcessImage(InputImage inputImage) async {
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

// A widget that draws the swatches for the [PaletteGenerator] it is given,
/// and shows the selected target colors.
class PaletteSwatches extends StatelessWidget {
  /// Create a Palette swatch.
  ///
  // / The [generator] is optional. If it is null, then the display will
  /// just be an empty container.
  const PaletteSwatches({Key? key, required this.generator}) : super(key: key);

  /// The [PaletteGenerator] that contains all of the swatches that we're going
  /// to display.
  final PaletteGenerator? generator;

  @override
  Widget build(BuildContext context) {
    final List<Widget> swatches = <Widget>[];
    final PaletteGenerator? paletteGen = generator;
    if (paletteGen == null || paletteGen.colors.isEmpty) {
      return Container();
    }
    for (final Color color in paletteGen.colors) {
      swatches.add(PaletteSwatch(color: color));
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Wrap(
          children: swatches,
        ),
        Container(height: 30.0),
        PaletteSwatch(
            label: 'Dominant', color: paletteGen.dominantColor?.color),
        PaletteSwatch(
            label: 'Light Vibrant', color: paletteGen.lightVibrantColor?.color),
        PaletteSwatch(label: 'Vibrant', color: paletteGen.vibrantColor?.color),
        PaletteSwatch(
            label: 'Dark Vibrant', color: paletteGen.darkVibrantColor?.color),
        PaletteSwatch(
            label: 'Light Muted', color: paletteGen.lightMutedColor?.color),
        PaletteSwatch(label: 'Muted', color: paletteGen.mutedColor?.color),
        PaletteSwatch(
            label: 'Dark Muted', color: paletteGen.darkMutedColor?.color),
      ],
    );
  }
}

/// A small square of color with an optional label.
@immutable
class PaletteSwatch extends StatelessWidget {
  /// Creates a PaletteSwatch.
  ///
  /// If the [paletteColor] has property `isTargetColorFound` as `false`,
  /// then the swatch will show a placeholder instead, to indicate
  /// that there is no color.
  const PaletteSwatch({
    Key? key,
    this.color,
    this.label,
  }) : super(key: key);

  /// The color of the swatch.
  final Color? color;

  /// The optional label to display next to the swatch.
  final String? label;

  @override
  Widget build(BuildContext context) {
    // Compute the "distance" of the color swatch and the background color
    // so that we can put a border around those color swatches that are too
    // close to the background's saturation and lightness. We ignore hue for
    // the comparison.
    final HSLColor hslColor = HSLColor.fromColor(color ?? Colors.transparent);
    final HSLColor backgroundAsHsl = HSLColor.fromColor(Colors.white);
    final double colorDistance = math.sqrt(
        math.pow(hslColor.saturation - backgroundAsHsl.saturation, 2.0) +
            math.pow(hslColor.lightness - backgroundAsHsl.lightness, 2.0));

    Widget swatch = Padding(
      padding: const EdgeInsets.all(2.0),
      child: color == null
          ? const Placeholder(
              fallbackWidth: 34.0,
              fallbackHeight: 20.0,
              color: Color(0xff404040),
              strokeWidth: 2.0,
            )
          : Container(
              decoration: BoxDecoration(
                  color: color,
                  border: Border.all(
                    width: 1.0,
                    color: Colors.black,
                    style: colorDistance < 0.2
                        ? BorderStyle.solid
                        : BorderStyle.none,
                  )),
              width: 34.0,
              height: 20.0,
            ),
    );

    if (label != null) {
      swatch = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 130.0, minWidth: 130.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            swatch,
            Container(width: 5.0),
            Text(label!),
          ],
        ),
      );
    }
    return swatch;
  }
}
