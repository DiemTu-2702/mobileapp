import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../entities/test_entity.dart';

import '../entities/result_entity.dart'; // Sẽ tạo ResultEntity sau

abstract class TestRepository {
  // Lấy danh sách tất cả các bài test
  Future<Either<Failure, List<TestEntity>>> getAvailableTests();

  // Lấy chi tiết một bài test dựa trên ID
  Future<Either<Failure, TestEntity>> getTestDetails(String testId);

  // Lưu kết quả làm bài
  Future<Either<Failure, ResultEntity>> submitTest(
      String testId,
      Map<String, int> userAnswers // {QuestionId: AnswerIndex}
      );
}