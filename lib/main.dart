import 'package:android_image_processing/camera/camera_view.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

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
      home: const HomeScreen(title: 'Android Image Processing'),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CustomPaint? _customPaint;
  PainterFeature _painterFeature = PainterFeature.ColorRecognition;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _setPainterFeature(PainterFeature feature) {
    setState(() {
      _painterFeature = feature;
    });
  }

  CustomPaint? _painter() {
    if (_painterFeature == PainterFeature.ObjectDetection) {
      // _painterFeature = // whatever it is.
    }
    if (_painterFeature == PainterFeature.ColorRecognition) {
      // _painterFeature = // whatever it is.
    }
    if (_painterFeature == PainterFeature.TextRecognition) {
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
          CameraView(
            customPaint: _painter(),
            painterFeature: _painterFeature,
            onImage: ((inputImage) {}),
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
}

class PainterController extends StatefulWidget {
  const PainterController({
    Key? key,
    required this.setPainterFeature,
    required this.painterFeature,
  }) : super(key: key);

  final void Function(PainterFeature) setPainterFeature;
  final PainterFeature painterFeature;

  @override
  State<PainterController> createState() => PainterControllerState();
}

class PainterControllerState extends State<PainterController> {
  Widget _container(String text, PainterFeature feature) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: widget.painterFeature == feature
            ? [
                const BoxShadow(
                  color: Color.fromARGB(255, 73, 73, 73),
                  blurRadius: 7,
                  spreadRadius: 2,
                  offset: Offset(0.0, 5.0),
                ),
              ]
            : [
                const BoxShadow(color: Colors.transparent),
              ],
        color: widget.painterFeature == feature
            ? Colors.white
            : Colors.transparent,
        border: Border.all(color: Colors.white, width: 0.3),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          color: widget.painterFeature == feature ? Colors.pink : Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 115,
      right: 0,
      left: 0,
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  widget.setPainterFeature(PainterFeature.ObjectDetection),
              child: _container(
                  'Object Recognition', PainterFeature.ObjectDetection),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  widget.setPainterFeature(PainterFeature.ColorRecognition),
              child: _container(
                  'Color Recognition', PainterFeature.ColorRecognition),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () =>
                  widget.setPainterFeature(PainterFeature.TextRecognition),
              child: _container(
                  'Text Recognition', PainterFeature.TextRecognition),
            ),
          ),
        ],
      ),
    );
  }
}
