import 'package:equatable/equatable.dart';

class ResultEntity extends Equatable {
  final String testId;
  final String userId;
  final DateTime completionTime;
  final int correctAnswers;
  final int incorrectAnswers;
  final int scoreReading;
  final int timeSpentSeconds;

  const ResultEntity({
    required this.testId,
    required this.userId,
    required this.completionTime,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.scoreReading,
    required this.timeSpentSeconds,
  });

  @override
  List<Object?> get props => [
    testId,
    userId,
    completionTime,
    correctAnswers,
    incorrectAnswers,
    scoreReading,
    timeSpentSeconds,
  ];
}