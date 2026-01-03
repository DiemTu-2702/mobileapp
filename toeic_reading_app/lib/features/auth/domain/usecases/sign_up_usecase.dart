import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart'; // <<< Import Base UseCase
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// --- USE CASE ---
// UseCase cho việc Đăng ký
class SignUpUseCase implements UseCase<UserEntity, SignUpParams> {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(SignUpParams params) async {
    // Gọi hàm signUp trong Repository và truyền các tham số
    return await repository.signUp(
      email: params.email,
      password: params.password,
      name: params.name, // <<< Tham số Name mới
    );
  }
}

// --- PARAMS ---
// Class chứa các tham số cần thiết cho việc Đăng ký
class SignUpParams extends Equatable {
  final String email;
  final String password;
  final String name;

  const SignUpParams({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object> get props => [email, password, name];
}