# Android Based Image Processing

This is an Android Based Application capable of recognizing general objects in the surroundings, identifying colors in a landscape, and recognizing texts in images, with translation from Filipino to English and vice versa.

The android app is powered by Flutter, Google’s Cross Platform Mobile Development Framework. In addition, the machine learning models were created using Python and Tensorflow library. 

<br />

![Screenshot_1664265344.png](Android%20Based%20Image%20Processing%20b02367bae2a745219eeea83e2519e788/Screenshot_1664265344.png)

![Screenshot_1664265353.png](Android%20Based%20Image%20Processing%20b02367bae2a745219eeea83e2519e788/Screenshot_1664265353.png)

![Screenshot_1664265355.png](Android%20Based%20Image%20Processing%20b02367bae2a745219eeea83e2519e788/Screenshot_1664265355.png)

![Screenshot_1664265368.png](Android%20Based%20Image%20Processing%20b02367bae2a745219eeea83e2519e788/Screenshot_1664265368.png)

![Screenshot_1664265362.png](Android%20Based%20Image%20Processing%20b02367bae2a745219eeea83e2519e788/Screenshot_1664265362.png)

![Screenshot_1664265382.png](Android%20Based%20Image%20Processing%20b02367bae2a745219eeea83e2519e788/Screenshot_1664265382.png)

<br />
<br />
<br />
<br />

# lib (Main Directory of Code Base)

All of the necessary code inclusions are found in lib directory.

<br />
<br />

### Main (main.dart)

This is the starting point of the application. This is where the void main() function is invoked.

Methods:

initializeColorInterpreter()

- This sets the tfl interpreter for color predictions.

initializeCameraController()

- This instantiate the cameraController and initialized the necessary configuration of the camera. i.e. Zoom Level, Exposure, Focus, and Flash Mode.

startLiveFeed(void Function(CameraImage image) func)

- This will start an image stream from the camera.

stopLiveFeed() 

- This function will stop the current image stream.

zoomCallback(newSliderValue)

- Called by the slider widget on change, sets a new zoom level for the camera.

processCameraImage(CameraImage image, dynamic onImage)

- This Function Converts the CameraImage to an InputImage - usable for object detection and color recognition
- Returns InputImage

Map<String, int> getPixelIndices(CameraImage image)

- This will return the y and uv indices of a pixel offset from an YUV420 image.
- Return indices in Map {’y’: index, ‘uv’: index}

List<double> getPixelRGB(CameraImage image, int y, int uv)

- This will return the rgb value of the indexed pixel from the image. This will invoke the function yuv420ToRGB() to convert yuv pixel to rgb.

yuv420ToRGB(int y, int u, int v)

- Compute the conversion of yuv values to rgb values.

String identifyColor(List<List<double>> rgb) 

- Using the colorInterpreter set by initializeColorInterpreter, it will identify the color of the pixel of the clicked point of the user in the Camera View (Camera Preview).

setBoundingBoxColor(List<double> rgb)

- Used to set the bounding box color for Color Recognition Rectangle.

voiceOutIdentifiedColor(String color) 

- Will voice out the identified color by the machine learning model.

identifyColorFromImage(CameraImage image)

- This function invokes all the above functions to recognize the color of a specific pixel in an image.

processImageStream(CameraImage image)

- The resulting image stream from the Camera View will be processed here, invoking, processCameraImage() and identifyColorFromImage()

setAwaitOptions()

- Makes sure that the speaking process is complete

getDefaultEngine()

- Instantiates the flutterTts engine with the default engine provided by the flutter_tts library.

initializeTts()

- Initializes the Flutter Text to Speech Engine.

setPainterFeature(PainterFeature feature)

- Used by the painter controller as a callback function for each individual rounded buttons (Object, Color, Text).

onScreenClick(TapDownDetails details)

- Invoked by the GestureDetector widget to create a bounding box on the clicked area.

getClickBoundingBox(TapDownDetails details)

- Sets the bounding box coordinates of the clicked area. (Used only for Object Recognition Feature)

onCameraPreviewClick(TapDownDetails details, BoxConstraints constraints, Offset offset)

- Similar to the function before, however, this is used in ColorRecognition Feature.

CustomPaint rectanglePainter()

- Used to create a custom canvas painter - a rectangle painter capable of creating rectangles on screen wherever the user clicks.

CustomPaint? painterOne()

- This is passed on to the Camera View to draw on top of the Camera Preview. (Generally used by Object Recognition)

CustomPaint? painterTwo()

- This is passed on to the Camera View to draw on top of the Camera Preview. (Generally used by Object Recognition)

clear() 

processObjectDetectionImage(InputImage inputImage)

- Using the object detector model, this function will process the image from the image stream of the camera and recognize objects within the proximity of the clicked area of the user.

initializeObjectDetector(DetectionMode mode) 

- Initializes the object detector variable using the file path in the assets.

getObjectDetectorModelPath(String assetPath)

- This will return the absolute file path of the asset file.

<br />
<br />
<br />
<br />

# widgets (lib/widgets)

The widgets directory includes all widgets used in the entirety of the application. 

<br />
<br />

### Camera View (camera_view.dart)

This widget consume majority of the space on the screen. This is the component that takes images, as well as stream images for object or color recognition. 

Methods:

CroppedFile? cropImage(String path)

- This function calls the image cropper component from the library image_cropper and crop the image captured by the camera. This will return the cropped image.

Widget circleButton()

- This creates the floating action button of the screen. It will only show the circle button when the current painterFeature is textRecognition.

Widget? floatingActionButton()

- This function encapsulates the circleButton widget to itself.

onPreviewTapDown(TapDownDetails details, BoxConstraints constraints)

- This handles the on screen click of the camera view, wherein for each click, it will set the exposure point and focus point to its offset from the origin of the screen (0,0).

setCameraFlashMode()

- This function is invoked by the flash icon button. It toggles the camera flash mode from “always” (on) to “off”, and vice versa.

Widget liveFeedBody() 

- This is the main body of the widget, this displays a preview of what the camera is seeing at the moment.

<br />
<br />

### Main Header (main_header.dart)

This widget is used in the main screen (main.dart), it is the header part of the screen. It changes the headerText based on the current painterFeature.

Methods:

String headerText()

- The function determines which text (Object, Color, or Text) should be displayed in the screen.

exitApp()

- Used to programmatically exit the application.

goBackToPreviousScreen()

- Used to programmatically go back to the previous screen

<br />
<br />

### Painter Controller (painter_controller.dart)

This widget is found in the main screen (main.dart), it shows the object, color, and text buttons.

Methods: 

Widget container(String text, PainterFeature feature)

- This will create one rounded button together with its functionality (setPainterFeature).

<br />
<br />
<br />
<br />

# screens (lib/screens)

The screens directory includes all screens except the main screen, where the app revolves around. 

<br />
<br />

### Display Text Screen (display_text_screen.dart)

This is the screen showed in app when the user uses Text Recognition and takes a photo with the feature. To elaborate, when the user is done cropping the taken image, this is the screen that will popup.

This includes features like; voice out, translation from English-Filipino, vice versa, and speech rate (Voice Out Speed).

<br />

UI Variables:

isSpeaking (boolean)

- used to manipulate color of mic button when speaking.

isProcessing (boolean)

- used to show circle progress indicator (loading) on screen load and when translating texts.

showSpeechRateMenu (boolean)

- Speech Rate can be changed in this screen, the menu of speech rate is a popup menu. This variable will determine whether or not to show the speech rate menu on screen.

languageRecognized (boolean)

- This variable is used to determine if the language error components are to be shown in screen. When the language of the recognized text in the image is recognizable then this (languageRecognized) is true.

hasText (boolean)

- Similar to the previous, this is used to determine if the text error components are to be shown in screen.

<br />

Methods:

shouldTranslateToFilipino()

- A guard clause function used in translateText() to determine if the function should translate to Filipino.

shouldTranslateToEnglish()

- A guard clause function used in translateText() to determine if the function should translate to English.

translateText()

- This function is called by the Translate Button, it translates the text from source language to the target language. i.e. Filipino (Source) to English (Target). Additionally, the translated version is stored in a cache to minimize the translation computation of the function.

switchSourceAndTargetLanguage()

- Switches the Source and Target Language. i.e. Filipino to English then after calling the function, English (Source)  to Filipino (Target)

speak()

- This function uses the Global Variable flutterTts to voice out the text recognized by the machine learning model.

stop()

- Used to stop the application from voicing out texts.

microphoneClick() 

- This is invoked by the Microphone Button, it has 2 operations inside; speak() or stop(). If the application is currently speaking or voicing out, then the operation used is stop(). Otherwise, speak().

processImage()

- Called on initState() or initialization of screen, the function uses the text recognition model to identify texts in the image cropped and stores the recognized text to newVoiceText.

setSpeechRateState(double newRate)

- This function changes the voice out speed of the application, it has 6 corresponding speeds the user can choose from; 0.25, 0.5, 0.75, 1.0, 1.25, 1.50 and 1.75.

<br />
<br />
<br />
<br />

# painters (lib/painters)

This directory includes all the canvas painter of the application. These Canvas painters draw on top of the Camera View (Camera Preview) to show the color and/or bounding box for recognized objects. Also, one painter handles the creation of paragraphs and text for the Text Recognition. 

<br />
<br />

### Coordinates Translator (coordinates_translator.dart)

This is a file containing utility functions used in object detector painter.

Functions:

double translateX()

- This will translate the offset x based on the absolute size of the image and its rotation.

double translateY()

- This will translate the offset y based on the absolute size of the image and its rotation.

<br />
<br />

### Object Detector (object_detector_painter.dart)

This is the painter used when the active painterFeature is ObjectRecognition. This is used to create the bounding box on the recognized objects in the image stream.

<br />
<br />

### Paragraph Painter (paragraph_painter.dart)

This is the painter used in creating the paragraphs in display_text_screen. This turns strings to a paragraph in a canvas.

<br />
<br />

### Rectangle Painter (rectangle_painter.dart)

This painter is used when clicking on the screen while on ObjectRecognition mode. This displays the offset rectangle where the user points to.

<br />
<br />
<br />
<br />

# DO NOT TOUCH

- generated_plugin_registrant.dart
- pubspec.yaml
- build.gradle
- .flutter-plugins
- .flutter-plugins-dependencies
- assets/

<br />
<br />

# Run Application on Debug Mode

```dart
flutter run
```
<br />

# Build APK

```dart
flutter build apk
```
<br />

# Install APK to Android Device

Make that the Android Device is plugged in.

```dart
flutter install
```
