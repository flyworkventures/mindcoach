import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider =
NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    // null => sistem dili
    // İLERİDE: kaydedilmiş kullanıcı dili varsa burada set edilir
    return null;
  }

  void setLocale(Locale? newLocale) => state = newLocale;

  void resetToSystemLocale() => state = null;
}
