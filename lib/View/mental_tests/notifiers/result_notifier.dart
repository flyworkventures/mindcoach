import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResultState {
  final double score;       // 0.0 – 1.0
  final String level;       // Low / Moderate / High
  final String description; // Açıklama

  const ResultState({
    required this.score,
    required this.level,
    required this.description,
  });
}

class ResultNotifier extends Notifier<ResultState?> {
  @override
  ResultState? build() => null;

  void compute({
    required Map<int, int> answers,
    required String Function(double) levelResolver,
    required String Function(double) descriptionResolver,
  }) {
    if (answers.isEmpty) {
      state = null;
      return;
    }

    final totalScore = answers.values.reduce((a, b) => a + b);
    final maxScore = answers.length * 3;
    final normalized = totalScore / maxScore;

    state = ResultState(
      score: normalized,
      level: levelResolver(normalized),
      description: descriptionResolver(normalized),
    );
  }

  void clear() => state = null;
}

final resultProvider = NotifierProvider<ResultNotifier, ResultState?>(
  ResultNotifier.new,
);
