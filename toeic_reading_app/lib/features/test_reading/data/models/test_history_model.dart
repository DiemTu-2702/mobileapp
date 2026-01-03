import 'package:cloud_firestore/cloud_firestore.dart';

class TestHistoryModel {
  final String id;
  final String testId; // Bắt buộc có để load lại đề
  final String testTitle;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final DateTime date;

  // Giữ nguyên là Map như cách bạn lưu trong Bloc
  // Key: questionId, Value: selectedIndex (có thể null)
  final Map<String, dynamic> userAnswers;

  TestHistoryModel({
    required this.id,
    required this.testId,
    required this.testTitle,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.date,
    required this.userAnswers,
  });

  factory TestHistoryModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TestHistoryModel(
      id: doc.id,
      testId: data['testId'] ?? '',
      testTitle: data['testTitle'] ?? 'Bài thi không tên',
      score: (data['score'] ?? 0).toInt(),
      totalQuestions: (data['totalQuestions'] ?? 0).toInt(),
      correctAnswers: (data['correctCount'] ?? 0).toInt(), // Lưu ý key 'correctCount' trong Bloc của bạn
      date: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      // Lấy trực tiếp Map từ Firestore
      userAnswers: data['userAnswers'] != null
          ? Map<String, dynamic>.from(data['userAnswers'])
          : {},
    );
  }
}