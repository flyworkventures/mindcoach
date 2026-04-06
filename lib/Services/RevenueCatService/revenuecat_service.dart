import 'dart:io';

import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenuecatService {

Future<void> initializeRevenueCat() async {
  try {
    String apiKey;
    if (Platform.isIOS) {
      // appl_pOEGBUSRqhfvvHeqqhIwBImdKlO
      apiKey = 'appl_cmngPyTEtrlLNOqWdXOfiCDYRMZ';
    } else if (Platform.isAndroid) {
      apiKey = 'test_ozLECgwkQYqdCmDOKJltIIiINCG';
    } else {
      throw UnsupportedError('Platform not supported');
    }
    debugPrint(apiKey);
    await Purchases.setLogLevel(LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    debugPrint("✅ RevenueCat initialized successfully");
  } catch (e) {
    // Hatayı logla ama uygulamayı çökerme
    debugPrint("⚠️ RevenueCat initialization failed: $e");
    debugPrint("App will continue without premium features");
  }
}

}
