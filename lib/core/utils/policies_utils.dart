import 'package:flutter/material.dart';

String localizedMD(String baseName, BuildContext context) {
  final locale = Localizations.localeOf(context);
  final lang = locale.languageCode; // en, tr, de...

  final candidate = "assets/policies/$lang/$baseName.md";

  // Desteklenen diller
  const supported = ["en", "tr", "de"];

  if (supported.contains(lang)) {
    return candidate;
  }

  // fallback
  return "assets/policies/en/$baseName.md";
}
