import 'package:mindcoach/core/config/size_config.dart';

extension SizeExtensions on num {
  double get w => this * SizeConfig.scaleW;
  double get h => this * SizeConfig.scaleH;
}
