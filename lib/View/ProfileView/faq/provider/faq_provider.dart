import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/faq_model.dart';

/// JSON'dan FAQ listesini okuyan provider
final faqListProvider = FutureProvider<List<FaqItem>>((ref) async {
  final raw = await rootBundle.loadString('assets/json/faq.json');
  final decoded = jsonDecode(raw) as Map<String, dynamic>;

  // Kategori adları (kategori anahtarı -> dil -> metin)
  final categoriesRaw = decoded['categories'] as Map<String, dynamic>? ?? {};
  final categories = categoriesRaw.map(
    (key, value) => MapEntry(
      key,
      (value as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as String),
      ),
    ),
  );

  final list = decoded['faq'] as List<dynamic>;

  return list
      .map(
        (e) => FaqItem.fromJson(
          e as Map<String, dynamic>,
          categories: categories,
        ),
      )
      .toList();
});
