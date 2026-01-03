import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/test_entity.dart';
import '../repositories/test_repository.dart';

class GetAvailableTestsUseCase {
  final TestRepository repository;

  GetAvailableTestsUseCase(this.repository);

  Future<Either<Failure, List<TestEntity>>> call() async {
    // Logic nghiệp vụ (Ví dụ: kiểm tra bộ nhớ cache trước khi gọi API)
    return await repository.getAvailableTests();
  }
}