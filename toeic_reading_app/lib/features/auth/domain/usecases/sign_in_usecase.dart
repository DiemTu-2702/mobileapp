import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart'; // Cần thêm gói này để so sánh object

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart'; // Import interface UseCase gốc
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// 1. Implement interface UseCase<Type, Params>
class SignInUseCase implements UseCase<UserEntity, SignInParams> {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  @override
  // 2. Hàm call nhận 1 tham số là object Params
  Future<Either<Failure, UserEntity>> call(SignInParams params) async {
    return await repository.signIn(
      email: params.email,
      password: params.password,
    );
  }
}

// 3. Định nghĩa class Params để đóng gói tham số
class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}