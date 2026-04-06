import 'package:meta/meta.dart';

@immutable
class FaqItem {
  final int id;
  final Map<String, String> question;
  final Map<String, String> answer;

  const FaqItem({
    required this.id,
    required this.question,
    required this.answer,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      id: json['id'] as int,
      question: (json['question'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as String)),
      answer: (json['answer'] as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, value as String)),
    );
  }
}
