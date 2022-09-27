import 'package:android_image_processing/main.dart';
import 'package:android_image_processing/painters/paragraph_painter.dart';
import 'package:android_image_processing/widgets/main_header.dart';
import 'package:flutter/material.dart';
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
  String? newVoiceText;
  /* */

  /* Text Recognition Variables */
  final TextRecognizer textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  InputImage? inputImage;
  /* */

  /* UI Variables */
  bool isSpeaking = false;
  bool isProcessing = true;
  bool showSpeechRateMenu = false;
  bool languageRecognized = false;
  bool hasText = false;
  /* */

  /* Translation Variables */
  bool translating = false;
  late TranslateLanguage sourceLanguage;
  late TranslateLanguage targetLanguage;

  late OnDeviceTranslator onDeviceTranslator;
  /* */

  /* TTS Variables */
  double speechRate = 0.5;
  /* TTS Variables */

  /* Cache */
  final Map<String, String> _cache = {};

  @override
  void initState() {
    super.initState();
    processImage();
  }

  bool shouldTranslateToFilipino() {
    return targetLanguage == TranslateLanguage.tagalog &&
        _cache.keys.contains('Filipino');
  }

  bool shouldTranslateToEnglish() {
    return targetLanguage == TranslateLanguage.english &&
        _cache.keys.contains('English');
  }

  Future translateText() async {
    setState(() => translating = true);

    if (shouldTranslateToEnglish()) {
      newVoiceText = _cache['English'];
      translating = false;
      switchSourceAndTargetLanguage();
      setState(() {});
      return;
    }

    if (shouldTranslateToFilipino()) {
      newVoiceText = _cache['Filipino'];
      translating = false;
      switchSourceAndTargetLanguage();
      setState(() {});
      return;
    }

    String response = await onDeviceTranslator.translateText(newVoiceText!);
    _cache[sourceLanguage == TranslateLanguage.english
        ? 'English'
        : 'Filipino'] = newVoiceText!;
    translating = false;
    switchSourceAndTargetLanguage();
    newVoiceText = response;
    setState(() {});
  }

  void switchSourceAndTargetLanguage() {
    final TranslateLanguage temp = sourceLanguage;
    sourceLanguage = targetLanguage;
    targetLanguage = temp;
  }

  Future speak() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(speechRate);
    await flutterTts.setPitch(pitch);

    if (newVoiceText != null) {
      if (newVoiceText!.isNotEmpty) {
        await flutterTts.speak(newVoiceText!);
      } else {
        await flutterTts.speak('No Texts Recognized, cannot Read!');
      }

      stop();
      isSpeaking = false;
      setState(() {});
    }
  }

  Future stop() async {
    await flutterTts.stop();
  }

  void microphoneClick() {
    if (isSpeaking) {
      stop();
      isSpeaking = false;
      setState(() {});
      return;
    }

    speak();
    isSpeaking = true;
    setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
    stop();
    textRecognizer.close();
  }

  Future<void> processImage() async {
    isProcessing = true;
    setState(() {});
    inputImage = InputImage.fromFilePath(widget.imagePath);
    final recognizedText =
        await textRecognizer.processImage(inputImage as InputImage);

    if (recognizedText.blocks.isEmpty) {
      isProcessing = false;
      hasText = false;
      setState(() {});
      return;
    }

    String text = '';
    for (var block in recognizedText.blocks) {
      for (var line in block.lines) {
        text += '${line.text} ';
      }
      text += '\n\n';
    }

    newVoiceText = text;
    language = recognizedText.blocks[0].recognizedLanguages[0];
    if (language == 'en') {
      sourceLanguage = TranslateLanguage.english;
      targetLanguage = TranslateLanguage.tagalog;
      onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      languageRecognized = true;
      hasText = true;
    }

    if (language == 'fil' || language == 'tl' || language == 'ceb') {
      sourceLanguage = TranslateLanguage.tagalog;
      targetLanguage = TranslateLanguage.english;
      onDeviceTranslator = OnDeviceTranslator(
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      languageRecognized = true;
      hasText = true;
    }

    if (language != 'en' &&
        (language != 'fil' || language != 'tl' || language != 'ceb')) {
      languageRecognized = false;
      hasText = true;
    }

    isProcessing = false;
    setState(() {});
  }

  void setSpeechRateState(double newRate) {
    speechRate = newRate;
    showSpeechRateMenu = false;
    setState(() {});
  }

  String speechRateConversion() {
    if (speechRate == 0.01) return '0.25';
    if (speechRate == 0.15) return '0.5';
    if (speechRate == 0.25) return '0.75';
    if (speechRate == 0.5) return '1.0';
    if (speechRate == 0.75) return '1.25';
    if (speechRate == 1) return '1.50';
    return '1.75';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: (isProcessing)
          ? const SafeArea(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : (hasText)
              ? SafeArea(
                  child: (languageRecognized)
                      ? Column(
                          children: [
                            const MainHeader(
                              painterFeature: PainterFeature.textRecognition,
                              isMain: false,
                            ),
                            translating
                                ? const Expanded(
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (showSpeechRateMenu) {
                                          showSpeechRateMenu = false;
                                          setState(() {});
                                        }
                                      },
                                      child: SingleChildScrollView(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 30,
                                            vertical: 40,
                                          ),
                                          child: CustomPaint(
                                            painter: ParagraphPainter(
                                                text: newVoiceText ?? ''),
                                            size: Size.infinite,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ],
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(
                                    bottom: 50,
                                  ),
                                  child: const Text(
                                    'Language Error',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 36,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const Text(
                                  'The Language was not recognized by the system. Try another text.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 20),
                                  child: ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                          vertical: 15, horizontal: 30),
                                      child: Text(
                                        'Go Back',
                                        style: TextStyle(fontFamily: 'Poppins'),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                )
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                            bottom: 50,
                          ),
                          child: const Text(
                            'Text Error',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 36,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Text(
                          'Image has no recognizable text.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 15, horizontal: 30),
                              child: Text(
                                'Go Back',
                                style: TextStyle(fontFamily: 'Poppins'),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: (!isProcessing && languageRecognized)
          ? SizedBox(
              height: MediaQuery.of(context).size.height * 0.26,
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromARGB(15, 65, 65, 65),
                          offset: Offset(0, -1),
                          blurRadius: 7,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 11),
                          width: MediaQuery.of(context).size.width,
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.blueGrey,
                                width: 0.2,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Source Language',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        sourceLanguage ==
                                                TranslateLanguage.english
                                            ? 'English'
                                            : 'Filipino',
                                        style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 20),
                                    child: Icon(Icons.arrow_right_alt_sharp,
                                        size: 30),
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Target Language',
                                        style: TextStyle(
                                          color: Colors.blueGrey,
                                          fontFamily: 'Poppins',
                                          fontSize: 10,
                                        ),
                                      ),
                                      Text(
                                        targetLanguage ==
                                                TranslateLanguage.english
                                            ? 'English'
                                            : 'Filipino',
                                        style: const TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 15),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Stack(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      showSpeechRateMenu = true;
                                      setState(() {});
                                    },
                                    icon: const Icon(
                                      Icons.slow_motion_video_outlined,
                                      size: 26,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    left: 28,
                                    bottom: 20,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black,
                                      foregroundColor: Colors.white,
                                      child: Text(
                                        speechRateConversion(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      primary: Colors.white,
                                      onPrimary: Colors.pink,
                                    ),
                                    onPressed: translateText,
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 15),
                                      child: Text('Translate'),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: microphoneClick,
                          child: Material(
                            elevation: 5,
                            borderRadius: BorderRadius.circular(100),
                            child: CircleAvatar(
                              backgroundColor:
                                  isSpeaking ? Colors.pink : Colors.white,
                              foregroundColor:
                                  isSpeaking ? Colors.white : Colors.pink,
                              radius: 39,
                              child:
                                  Icon(!isSpeaking ? Icons.mic : Icons.mic_off),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showSpeechRateMenu)
                    Positioned(
                      right: 45,
                      left: 20,
                      bottom: 38,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          border:
                              Border.all(color: Colors.blueGrey, width: 0.2),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(19, 54, 54, 54),
                              offset: Offset(0, 1),
                              blurRadius: 10,
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                        width: MediaQuery.of(context).size.width * 0.8,
                        height: MediaQuery.of(context).size.height * 0.18,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => setSpeechRateState(0.01),
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: Text('0.25x'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => setSpeechRateState(0.15),
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: Text('0.50x'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => setSpeechRateState(0.25),
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: Text('0.75x'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => setSpeechRateState(0.5),
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: Text('1x (Normal)'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => setSpeechRateState(0.75),
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: Text('1.25x'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => setSpeechRateState(1),
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: Text('1.50x'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => setSpeechRateState(1.25),
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 10),
                                        child: Text('1.75x'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          : SizedBox(
              height: MediaQuery.of(context).size.height * 0,
              child: Container(),
            ),
    );
  }
}
