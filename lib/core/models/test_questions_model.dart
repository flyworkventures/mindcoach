// Test verileri (Dummy)
class Question {
  final int id;
  final String text;

  const Question(this.id, this.text);


  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      json['id'] as int,
      json['text'] as String,
    );
  }
}