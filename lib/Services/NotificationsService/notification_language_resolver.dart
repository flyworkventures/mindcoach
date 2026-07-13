import 'dart:ui' as ui;

import 'package:mindcoach/Services/LocalServices/local_db_service.dart';
import 'package:mindcoach/core/utils/local_db_keys.dart';

/// Uygulamanın gösterdiği dil ile bildirim dilini hizalar.
/// Öncelik: kayıtlı locale tercihi → cihaz dili.
class NotificationLanguageResolver {
  static const Set<String> supported = {
    'en', 'tr', 'de', 'es', 'fr', 'hi', 'it', 'ja', 'ko', 'pt', 'ru', 'zh',
  };

  static final LocalDbService _db = LocalDbService();

  static Future<String> resolve() async {
    try {
      final saved = await _db.getString(key: LocalDbKeys.locale);
      if (saved != null && saved.trim().isNotEmpty) {
        return normalize(saved);
      }
    } catch (_) {}
    return normalize(ui.PlatformDispatcher.instance.locale.languageCode);
  }

  static String normalize(String? code) {
    if (code == null || code.trim().isEmpty) return 'tr';
    final base = code.toLowerCase().split(RegExp(r'[-_]')).first;
    return supported.contains(base) ? base : 'tr';
  }
}
