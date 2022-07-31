import 'dart:io';

import 'package:android_image_processing/painters/paragraph_painter.dart';
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
  /* Text to Speech variables */
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
  /* */
  /* */
  /* */

  /* Text Recognition Variables */
  final TextRecognizer textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  InputImage? _inputImage;
  RecognizedText? _recognizedText;
  /* */

  /* UI Variables */
  bool _isSpeaking = false;

  double _calculateHeight() {
    double height = 0.0;
    for (var block in _recognizedText!.blocks) {
      height += block.lines.length;
    }
    return height * 35;
  }

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
      } else {
        await flutterTts.speak('No Texts Recognized, cannot Read!');
      }
    }
  }

  Future _stop() async {
    await flutterTts.stop();
  }

  void _buttonOnClick() {
    if (_isSpeaking) {
      _stop();
      _isSpeaking = false;
      setState(() {});
      return;
    }

    _speak();
    _isSpeaking = true;
    setState(() {});
    return;
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

    String text = '';
    for (var block in _recognizedText!.blocks) {
      for (var line in block.lines) {
        text += '${line.text} ';
      }
      text += '\n\n';
    }
    setState(() {
      _newVoiceText = text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: CustomPaint(
              painter: ParagraphPainter(text: _newVoiceText as String),
              size: Size.infinite,
            ),
          ),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTap: _buttonOnClick,
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(100),
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 39,
            child: Icon(!_isSpeaking ? Icons.mic : Icons.mic_off),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
