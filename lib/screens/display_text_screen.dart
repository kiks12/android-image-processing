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
  /* */

  /* Transalation Variables */
  bool _translating = false;
  late TranslateLanguage sourceLanguage;
  late TranslateLanguage targetLanguage;

  late OnDeviceTranslator onDeviceTranslator;
  /* */

  /* Cache */
  final Map<String, String> _cache = {};

  @override
  void initState() {
    super.initState();
    processImage();
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

  bool translateToFilipino() {
    return targetLanguage == TranslateLanguage.tagalog &&
        _cache.keys.contains('Filipino');
  }

  bool translateToEnglish() {
    return targetLanguage == TranslateLanguage.english &&
        _cache.keys.contains('English');
  }

  Future _translateText() async {
    setState(() => _translating = true);

    if (translateToEnglish()) {
      _newVoiceText = _cache['English'];
      _translating = false;
      _switchSourceAndTargetLanguages();
      setState(() {});
      return;
    }

    if (translateToFilipino()) {
      _newVoiceText = _cache['Filipino'];
      _translating = false;
      _switchSourceAndTargetLanguages();
      setState(() {});
      return;
    }

    String response = await onDeviceTranslator.translateText(_newVoiceText!);
    _cache[sourceLanguage == TranslateLanguage.english
        ? 'English'
        : 'Filipino'] = _newVoiceText!;
    _translating = false;
    _switchSourceAndTargetLanguages();
    _newVoiceText = response;
    setState(() {});
  }

  void _switchSourceAndTargetLanguages() {
    final TranslateLanguage temp = sourceLanguage;
    sourceLanguage = targetLanguage;
    targetLanguage = temp;
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
    final recognizedText =
        await textRecognizer.processImage(_inputImage as InputImage);

    String text = '';
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        text += '${line.text} ';
      }
      text += '\n\n';
    }
    setState(() {
      _newVoiceText = text;
      _recognizedText = recognizedText;
      if (recognizedText.blocks[0].recognizedLanguages[0] == 'en') {
        sourceLanguage = TranslateLanguage.english;
        targetLanguage = TranslateLanguage.tagalog;
        onDeviceTranslator = OnDeviceTranslator(
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        );
      } else {
        sourceLanguage = TranslateLanguage.tagalog;
        targetLanguage = TranslateLanguage.english;
        onDeviceTranslator = OnDeviceTranslator(
          sourceLanguage: sourceLanguage,
          targetLanguage: targetLanguage,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _translating
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: CustomPaint(
                    painter: ParagraphPainter(text: _newVoiceText ?? ''),
                    size: Size.infinite,
                  ),
                ),
              ),
      ),
      bottomNavigationBar: Container(
        height: MediaQuery.of(context).size.height * 0.22,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  sourceLanguage == TranslateLanguage.english
                      ? 'English'
                      : 'Filipino',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.arrow_right_alt_sharp, size: 30),
                ),
                Text(
                  targetLanguage == TranslateLanguage.english
                      ? 'English'
                      : 'Filipino',
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          primary: Colors.white,
                          onPrimary: Colors.pink,
                        ),
                        onPressed: _translateText,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          child: Text('Translate'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _buttonOnClick,
              child: Material(
                elevation: 5,
                borderRadius: BorderRadius.circular(100),
                child: CircleAvatar(
                  backgroundColor: _isSpeaking ? Colors.pink : Colors.white,
                  foregroundColor: _isSpeaking ? Colors.white : Colors.pink,
                  radius: 39,
                  child: Icon(!_isSpeaking ? Icons.mic : Icons.mic_off),
                ),
              ),
            ),
          ],
        ),
      ),
      // floatingActionButton: GestureDetector(
      //   onTap: _buttonOnClick,
      //   child:
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
