// lib/features/auth/presentation/bloc/auth_state.dart
// (Sử dụng cấu trúc cho phép import ở file Bloc chính)

part of 'auth_bloc.dart';

// Abstract class chung cho tất cả các trạng thái
abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object> get props => [];
}

// 1. Trạng thái ban đầu
class AuthInitial extends AuthState {}

// 2. Trạng thái đang tải (Loading)
class AuthLoading extends AuthState {}

// 3. ĐÃ ĐĂNG NHẬP THÀNH CÔNG (Cần tham số user)
class Authenticated extends AuthState {
  final UserEntity user;
  const Authenticated({required this.user});
  @override
  List<Object> get props => [user];
}

// 4. Trạng thái thành công sau khi submit form (vd: Đăng ký thành công)
class AuthSuccess extends AuthState {
  final UserEntity user;
  const AuthSuccess(this.user);
  @override
  List<Object> get props => [user];
}

// 5. Trạng thái thất bại
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object> get props => [message];
}

// 6. Trạng thái CHƯA ĐĂNG NHẬP (Unauthenticated)
class Unauthenticated extends AuthState {}