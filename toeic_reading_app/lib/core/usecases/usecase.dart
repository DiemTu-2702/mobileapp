import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart'; // Import Failure

// UseCase cơ sở cho các Use Case KHÔNG yêu cầu tham số
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// Class tham số đặc biệt khi một Use Case không cần tham số đầu vào
class NoParams extends Equatable {
  @override
  List<Object?> get props => [];
}

// UseCase cơ sở cho các Use Case có thể ném lỗi mà không cần trả về giá trị
abstract class VoidUseCase<Params> {
  Future<Either<Failure, void>> call(Params params);
}