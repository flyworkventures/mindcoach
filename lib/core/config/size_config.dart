import 'package:flutter/widgets.dart';

class SizeConfig {
  static late double scaleW;
  static late double scaleH;

  static const double designWidth = 394;
  static const double designHeight = 852;

  static void init(BuildContext context) {
    final size = MediaQuery.of(context).size;
    scaleW = size.width / designWidth;
    scaleH = size.height / designHeight;
  }

  static double w(double value) => value * scaleW;
  static double h(double value) => value * scaleH;
}
