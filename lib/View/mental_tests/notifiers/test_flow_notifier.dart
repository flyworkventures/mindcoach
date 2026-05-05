import 'package:flutter_riverpod/flutter_riverpod.dart';

class TestFlowState {
  final String? testName;
  final String? testTitle;
  final String? imagePath;
  final int totalQuestions;
  final int questionSeed;

  const TestFlowState({
    this.testName,
    this.testTitle,
    this.imagePath,
    this.totalQuestions = 0,
    this.questionSeed = 0,
  });

  TestFlowState copyWith({
    String? testName,
    String? testTitle,
    String? imagePath,
    int? totalQuestions,
    int? questionSeed,
  }) {
    return TestFlowState(
      testName: testName ?? this.testName,
      testTitle: testTitle ?? this.testTitle,
      imagePath: imagePath ?? this.imagePath,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      questionSeed: questionSeed ?? this.questionSeed,
    );
  }
}

class TestFlowNotifier extends Notifier<TestFlowState> {
  @override
  TestFlowState build() => const TestFlowState();

  void initTest({
    required String testName,
    required String testTitle,
    required String imagePath,
    required int totalQuestions,
  }) {
    state = TestFlowState(
      testName: testName,
      testTitle: testTitle,
      imagePath: imagePath,
      totalQuestions: totalQuestions,
      questionSeed: DateTime.now().microsecondsSinceEpoch,
    );
  }

  void reset() => state = const TestFlowState();
}

final testFlowProvider =
NotifierProvider<TestFlowNotifier, TestFlowState>(TestFlowNotifier.new);
