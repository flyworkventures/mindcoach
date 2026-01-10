import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestQuestionState {
  final int currentIndex;              // 1..totalQuestions
  final Map<int, int> selectedAnswers; // {questionId: answerIndex}

  const TestQuestionState({
    this.currentIndex = 1,
    this.selectedAnswers = const {},
  });

  TestQuestionState copyWith({
    int? currentIndex,
    Map<int, int>? selectedAnswers,
  }) {
    return TestQuestionState(
      currentIndex: currentIndex ?? this.currentIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
    );
  }
}

class TestQuestionNotifier extends Notifier<TestQuestionState> {
  @override
  TestQuestionState build() => const TestQuestionState();

  void goToQuestion(int index) {
    state = state.copyWith(currentIndex: index);
  }

  void selectAnswer({
    required int questionId,
    required int answerIndex,
  }) {
    final newMap = Map<int, int>.from(state.selectedAnswers);
    newMap[questionId] = answerIndex;
    state = state.copyWith(selectedAnswers: newMap);
  }

  void reset() => state = const TestQuestionState();
}

final testQuestionProvider =
NotifierProvider.autoDispose<TestQuestionNotifier, TestQuestionState>(
  TestQuestionNotifier.new,
);
