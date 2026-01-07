part of 'test_work_bloc.dart';

abstract class TestWorkState extends Equatable {
  const TestWorkState();

  @override
  List<Object?> get props => [];
}

class TestLoading extends TestWorkState {}

class TestInProgress extends TestWorkState {
  final List<QuestionEntity> questions;
  final int remainingSeconds;

  const TestInProgress({
    required this.questions,
    required this.remainingSeconds,
  });
  TestInProgress copyWith({
    List<QuestionEntity>? questions,
    int? remainingSeconds,
  }) {
    return TestInProgress(
      questions: questions ?? this.questions,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
  @override
  List<Object> get props => [questions, remainingSeconds];
}

class TestSubmitted extends TestWorkState {
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final String testId;

  const TestSubmitted({
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.testId,
  });

  @override
  List<Object> get props => [score, correctAnswers, totalQuestions, testId];
}

class TestError extends TestWorkState {
  final String message;
  const TestError(this.message);

  @override
  List<Object> get props => [message];
}