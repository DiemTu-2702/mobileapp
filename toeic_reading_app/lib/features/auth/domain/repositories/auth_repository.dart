import 'package:dartz/dartz.dart'; // Thư viện dartz để xử lý lỗi/kết quả thành công

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  // Phương thức Đăng nhập
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  });

  // Phương thức Đăng ký
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name,
  });
  Future<void> signOut();
  // Kiểm tra trạng thái đăng nhập
  Future<Either<Failure, UserEntity>> checkAuthStatus();
}