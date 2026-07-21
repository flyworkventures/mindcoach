import 'package:flutter/foundation.dart';
import 'package:mindcoach/http/http_service.dart';
import 'package:mindcoach/core/utils/app_constants.dart';

/// Uygulama dili ile backend `nativeLang` alanını senkron tutar (push bildirimleri için).
class NativeLangSync {
  static Future<void> syncToBackend(String languageCode) async {
    final code = languageCode.trim().toLowerCase();
    if (code.isEmpty) return;

    try {
      final http = HttpService();
      await http.put(
        path: AppConstants.completeProfileURL,
        body: {'nativeLang': code},
      );
    } catch (e) {
      debugPrint('[LANG] nativeLang sync failed: $e');
    }
  }
}
