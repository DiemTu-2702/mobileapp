import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart'; // Import NoParams từ đây
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

// UseCase phải implement UseCase<Type, Params>
class CheckAuthStatusUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  @override
  // Hàm call phải nhận tham số NoParams (dù không dùng đến)
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.checkAuthStatus();
  }
}