import 'dart:io';
import 'dart:ui';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';

double translateX(double x, Size size, Size absoluteImageSize) {
  return x * size.width / absoluteImageSize.width;
}

double translateY(
    double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
  switch (rotation) {
    case InputImageRotation.rotation90deg:
    case InputImageRotation.rotation270deg:
      return y *
          size.height /
          (Platform.isIOS ? absoluteImageSize.height : absoluteImageSize.width);
    default:
      return y * size.height / absoluteImageSize.height;
  }
}
