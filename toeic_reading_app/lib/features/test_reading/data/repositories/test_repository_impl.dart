import 'package:dartz/dartz.dart';

import '../../../../../core/error/failures.dart';
import '../../../../../core/error/exceptions.dart';
import '../../domain/entities/test_entity.dart';
import '../../domain/repositories/test_repository.dart';
import '../../domain/entities/result_entity.dart';
import '../datasources/test_remote_datasource.dart';

class TestRepositoryImpl implements TestRepository {
  final TestRemoteDataSource remoteDataSource;

  TestRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<TestEntity>>> getAvailableTests() async {
    try {
      final testModels = await remoteDataSource.fetchAvailableTests();
      // Trả về List<TestEntity> (TestModel kế thừa TestEntity)
      return Right(testModels);
    } on ServerException catch (e) {
      return Left(ServerFailure()); // Ánh xạ lỗi
    }
  }

  @override
  Future<Either<Failure, TestEntity>> getTestDetails(String testId) async {
    try {
      final testModel = await remoteDataSource.fetchTestDetails(testId);
      return Right(testModel);
    } on ServerException catch (e) {
      return Left(ServerFailure());
    }
  }

  @override
  Future<Either<Failure, ResultEntity>> submitTest(String testId, Map<String, int> userAnswers) {
    // Triển khai logic gửi đáp án và nhận ResultModel
    // Tạm thời trả về lỗi cho đến khi ResultEntity và logic được tạo
    throw UnimplementedError();
  }
}