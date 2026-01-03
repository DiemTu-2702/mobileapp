part of 'auth_bloc.dart';

// Abstract class chung cho tất cả các sự kiện
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

// 1. Sự kiện khi người dùng nhấn nút Đăng nhập
class SignInEvent extends AuthEvent {
  final String email;
  final String password;

  const SignInEvent({required this.email, required this.password});

  @override
  List<Object> get props => [email, password, password];
}

// 2. Sự kiện khi người dùng Đăng ký (Chức năng 1)
class SignUpEvent extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const SignUpEvent({
    required this.email,
    required this.password,
    required this.name
  });

  @override
  List<Object> get props => [email, password, name];
}
class SignOutEvent extends AuthEvent {}
// 3. Sự kiện kiểm tra trạng thái đăng nhập (để xử lý auto-login)
class CheckAuthStatusEvent extends AuthEvent {}