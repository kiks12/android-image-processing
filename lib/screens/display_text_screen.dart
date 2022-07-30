import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class DisplayTextScreen extends StatefulWidget {
  const DisplayTextScreen({
    Key? key,
    required this.imagePath,
  }) : super(key: key);

  final String imagePath;

  @override
  State<DisplayTextScreen> createState() => _DisplayTextScreenState();
}

class _DisplayTextScreenState extends State<DisplayTextScreen> {
  // Text to Speech variables
  late FlutterTts flutterTts;
  String? language;
  String? engine;
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  bool isCurrentLanguageInstalled = false;

  String? _newVoiceText;

  bool get isIOS => !kIsWeb && Platform.isIOS;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;
  bool get isWindows => !kIsWeb && Platform.isWindows;
  bool get isWeb => kIsWeb;
  //
  //

  // Text Recognition Variables
  final TextRecognizer textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  InputImage? _inputImage;
  RecognizedText? _recognizedText;

  @override
  void initState() {
    super.initState();
    processImage();
    sleep(const Duration(seconds: 2));
    initTts();
  }

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

  Future _speak() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (_newVoiceText != null) {
      if (_newVoiceText!.isNotEmpty) {
        await flutterTts.speak(_newVoiceText!);
      }
    }
  }

  Future _stop() async {
    await flutterTts.stop();
  }

  @override
  void dispose() {
    super.dispose();
    textRecognizer.close();
  }

  Future<void> processImage() async {
    _inputImage = InputImage.fromFilePath(widget.imagePath);
    _recognizedText =
        await textRecognizer.processImage(_inputImage as InputImage);
    _newVoiceText = _recognizedText!.text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Center(
            child: Image.file(
              File(widget.imagePath),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _speak();
            },
            child: const Text('Read'),
          ),
          ElevatedButton(
            onPressed: () {
              _stop();
            },
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }
}
