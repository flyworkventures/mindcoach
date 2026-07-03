import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindcoach/Http/http_service.dart';
import 'package:mindcoach/core/utils/app_constants.dart';

/// Bildirim tercihlerini (kategori opt-out + sessiz saat) backend ile senkronlar.
///
/// Hem provider [Ref] hem widget [WidgetRef] ile çağrılabilsin diye `ref`
/// dinamik tutulur; [HttpService] yalnızca gerçek [Ref] beklediğinden,
/// [WidgetRef] verildiğinde token yerel depodan (fallback) alınır.
class NotificationPreferencesRepo {
  final dynamic ref;
  NotificationPreferencesRepo([this.ref]);

  Ref? get _providerRef => ref is Ref ? ref as Ref : null;

  /// Mevcut tercihleri getirir. Kayıt yoksa backend varsayılanları döner.
  Future<Map<String, dynamic>> getPreferences() async {
    final http = HttpService(ref: _providerRef);
    final res = await http.get(path: AppConstants.notificationPreferencesURL);
    if (res.statusCode != 200) {
      throw Exception('Failed to get preferences: ${res.statusCode}');
    }
    final json = jsonDecode(res.body);
    return Map<String, dynamic>.from(json['data']['preferences'] ?? {});
  }

  /// Tercihleri günceller (kısmi güncelleme desteklenir).
  Future<Map<String, dynamic>> updatePreferences(
      Map<String, dynamic> body) async {
    final http = HttpService(ref: _providerRef);
    final res = await http.put(
      path: AppConstants.notificationPreferencesURL,
      body: body,
    );
    if (res.statusCode != 200) {
      throw Exception('Failed to update preferences: ${res.statusCode}');
    }
    final json = jsonDecode(res.body);
    return Map<String, dynamic>.from(json['data']['preferences'] ?? {});
  }
}
