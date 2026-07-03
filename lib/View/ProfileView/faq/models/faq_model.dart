import 'package:meta/meta.dart';

@immutable
class FaqItem {
  final int id;
  final String categoryKey;
  final Map<String, String> category;
  final Map<String, String> question;
  final Map<String, String> answer;

  const FaqItem({
    required this.id,
    required this.categoryKey,
    required this.category,
    required this.question,
    required this.answer,
  });

  factory FaqItem.fromJson(
    Map<String, dynamic> json, {
    Map<String, Map<String, String>> categories = const {},
  }) {
    final categoryKey = json['categoryKey'] as String? ?? '';
    return FaqItem(
      id: json['id'] as int,
      categoryKey: categoryKey,
      category: categories[categoryKey] ?? const {},
      question: (json['question'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as String)),
      answer: (json['answer'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as String)),
    );
  }
}
