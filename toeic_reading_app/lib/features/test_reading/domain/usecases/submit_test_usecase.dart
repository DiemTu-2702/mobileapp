import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/result_entity.dart';
import '../repositories/test_repository.dart';
import '../entities/test_entity.dart';

class SubmitTestUseCase {
  final TestRepository repository;

  SubmitTestUseCase(this.repository);

  Future<Either<Failure, ResultEntity>> call({
    required String testId,
    required TestEntity testDetails,
    required Map<String, int> userAnswers,
    required int timeSpentSeconds,
  }) async {
    // 1. Logic Tính toán Điểm số
    int correctAnswers = 0;

    // Lặp qua các câu hỏi của bài test để so sánh với đáp án người dùng
    for (var question in testDetails.questions) {
      // SỬA LỖI TẠI ĐÂY: Đổi 'correctAnswerIndex' thành 'correctIndex'
      if (userAnswers.containsKey(question.id) &&
          userAnswers[question.id] == question.correctIndex) {
        correctAnswers++;
      }
    }

    final totalQuestions = testDetails.totalQuestions;
    final incorrectAnswers = totalQuestions - correctAnswers;

    // Quy đổi điểm TOEIC
    final scoreReading = _calculateToeicReadingScore(correctAnswers, totalQuestions);

    // 2. Tạo Result Entity
    final resultEntity = ResultEntity(
      testId: testId,
      userId: 'mock_user_id', // Sau này sẽ thay bằng ID user thật từ AuthBloc
      completionTime: DateTime.now(),
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      scoreReading: scoreReading,
      timeSpentSeconds: timeSpentSeconds,
    );

    // 3. (Tạm thời trả về kết quả ngay, sau này sẽ gọi Repository để lưu)
    return Right(resultEntity);
  }

  // Hàm giả định tính điểm TOEIC Reading
  int _calculateToeicReadingScore(int correct, int total) {
    if (total == 0) return 0;

    // Giả sử thang điểm 495
    // Công thức đơn giản: (Số câu đúng / Tổng số câu) * 495
    return (correct / total * 495).round();
  }
}