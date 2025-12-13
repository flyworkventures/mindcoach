import 'package:flutter/widgets.dart';
import 'package:mindcoach/core/config/size_config.dart';

class LocaleFontScaler {
  LocaleFontScaler._();

  static double scale(BuildContext context, double base) {
    final lang = Localizations.localeOf(context).languageCode;

    double langFactor;
    switch (lang) {
      case 'de':
        langFactor = 0.88;
        break;
      case 'tr':
        langFactor = 0.95;
        break;
      default:
        langFactor = 1.0;
    }

    final widthFactor = SizeConfig.scaleW.clamp(0.9, 1.1);

    // Kullanıcının erişilebilirlik font büyütmesi
    final textScale = MediaQuery.textScaleFactorOf(context).clamp(0.9, 1.3);

    return base * langFactor * widthFactor * textScale;
  }
}
