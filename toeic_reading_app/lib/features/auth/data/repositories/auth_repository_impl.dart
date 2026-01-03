// lib/features/auth/data/repositories/auth_repository_impl.dart

import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart'; // UserModel

class AuthRepositoryImpl implements AuthRepository {
  // <<< KHẮC PHỤC LỖI 2: Undefined name 'remoteDataSource' >>>
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  // --- SIGN IN ---
  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.signIn(email, password);
      return Right(userModel);
    } on ServerException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure());
    }
  }

  // --- SIGN UP ---
  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String name, // Chữ ký đã khớp với AuthRepository
  }) async {
    try {
      // Gọi Data Source với 3 tham số (sau khi đã sửa lỗi 3)
      final userModel = await remoteDataSource.signUp(email, password, name);
      return Right(userModel);
    } on ServerException catch (e) {
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure());
    }
  }
  @override
  Future<void> signOut() async {
    await remoteDataSource.signOut();
  }
  // --- CHECK AUTH STATUS ---
  @override
  // <<< KHẮC PHỤC LỖI 1: Missing concrete implementation >>>
  Future<Either<Failure, UserEntity>> checkAuthStatus() async {
    try {
      final userModel = await remoteDataSource.checkAuthStatus();
      return Right(userModel);
    } on ServerException catch (e) {
      // Nếu chưa đăng nhập hoặc token hết hạn
      return Left(AuthFailure(e.message));
    } catch (e) {
      return Left(ServerFailure());
    }
  }
}