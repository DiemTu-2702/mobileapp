import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/test_entity.dart';
import '../repositories/test_repository.dart';

class GetTestDetailsUseCase {
  final TestRepository repository;

  GetTestDetailsUseCase(this.repository);

  // Use Case này nhận vào testId và trả về chi tiết bài test
  Future<Either<Failure, TestEntity>> call(String testId) async {
    return await repository.getTestDetails(testId);
  }
}