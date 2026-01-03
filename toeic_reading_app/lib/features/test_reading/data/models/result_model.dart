import '../../domain/entities/result_entity.dart';

class ResultModel extends ResultEntity {
  const ResultModel({
    required super.testId,
    required super.userId,
    required super.completionTime,
    required super.correctAnswers,
    required super.incorrectAnswers,
    required super.scoreReading,
    required super.timeSpentSeconds,
  });

  factory ResultModel.fromJson(Map<String, dynamic> json) {
    return ResultModel(
      testId: json['test_id'] as String,
      userId: json['user_id'] as String,
      // Chuyển đổi từ timestamp/string sang DateTime
      completionTime: DateTime.parse(json['completion_time'] as String),
      correctAnswers: json['correct_answers'] as int,
      incorrectAnswers: json['incorrect_answers'] as int,
      scoreReading: json['score_reading'] as int,
      timeSpentSeconds: json['time_spent_seconds'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'test_id': testId,
      'user_id': userId,
      'completion_time': completionTime.toIso8601String(), // Lưu dưới dạng chuỗi
      'correct_answers': correctAnswers,
      'incorrect_answers': incorrectAnswers,
      'score_reading': scoreReading,
      'time_spent_seconds': timeSpentSeconds,
    };
  }
}