import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

// Import Use Cases
import '../../domain/usecases/sign_in_usecase.dart';
import '../../domain/usecases/sign_up_usecase.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.checkAuthStatusUseCase,
  }) : super(AuthInitial()) {
    // Đăng ký các Handler
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<SignInEvent>(_onSignIn); // <<< QUAN TRỌNG: PHẢI CÓ DÒNG NÀY
    on<SignUpEvent>(_onSignUp);
    on<SignOutEvent>(_onSignOut);
  }

  // --- HANDLER: CHECK AUTH STATUS ---
  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await checkAuthStatusUseCase(NoParams());
    result.fold(
          (failure) => emit(Unauthenticated()), // Không lỗi, chỉ là chưa đăng nhập
          (user) => emit(Authenticated(user: user)),
    );
  }

  // --- HANDLER: SIGN IN (ĐĂNG NHẬP) ---
  Future<void> _onSignIn(SignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    // Gọi UseCase Đăng nhập
    final result = await signInUseCase(SignInParams(
      email: event.email,
      password: event.password,
    ));

    result.fold(
          (failure) => emit(AuthError(_mapFailureToMessage(failure))),
          (user) => emit(Authenticated(user: user)), // Thành công -> Authenticated
    );
  }

  // --- HANDLER: SIGN UP (ĐĂNG KÝ) ---
  Future<void> _onSignUp(SignUpEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());

    final result = await signUpUseCase(SignUpParams(
      email: event.email,
      password: event.password,
      name: event.name,
    ));

    result.fold(
          (failure) => emit(AuthError(_mapFailureToMessage(failure))),
          (user) => emit(Authenticated(user: user)), // Thành công -> Authenticated
    );
  }

  Future<void> _onSignOut(SignOutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await FirebaseAuth.instance.signOut();

    emit(Unauthenticated());
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return failure.message ?? 'Lỗi máy chủ';
    } else if (failure is AuthFailure) {
      return failure.message; // Thông báo lỗi cụ thể (sai pass, user không tồn tại...)
    }
    return 'Đã xảy ra lỗi không xác định';
  }
}