import 'package:equatable/equatable.dart';
import 'question_entity.dart';

// Đại diện cho một Bài Test TOEIC (ví dụ: TOEIC 2024 Test 1)
class TestEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final int totalQuestions;
  final String imageUrl;
  final List<QuestionEntity> questions;
  final int timeLimitMinutes; // Ví dụ: 75 phút cho Reading

  const TestEntity({
    required this.id,
    required this.title,
    this.description = '',
    required this.totalQuestions,
    this.imageUrl = '',
    this.questions = const [],
    required this.timeLimitMinutes,

  });

  @override
  List<Object?> get props => [id, title, totalQuestions, questions, timeLimitMinutes];
}