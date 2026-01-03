import 'package:equatable/equatable.dart';

// Abstract class chung cho tất cả các Failure
abstract class Failure extends Equatable {
  // Thêm tham số message vào abstract class
  final String message;

  // Constructor mặc định với thông báo lỗi chung
  const Failure([this.message = 'Đã xảy ra lỗi không xác định.']);

  @override
  // Đảm bảo message được đưa vào props để so sánh
  List<Object?> get props => [message];
}

// 1. Lỗi Máy chủ (ví dụ: lỗi 500 hoặc lỗi Parse data)
class ServerFailure extends Failure {
  // Ghi đè constructor và gọi super
  const ServerFailure([String message = 'Lỗi máy chủ. Vui lòng thử lại sau.'])
      : super(message);
}

// 2. Lỗi Mạng (Không có kết nối)
class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Không có kết nối mạng.'])
      : super(message);
}

// 3. Lỗi Xác thực (Đăng nhập/Đăng ký)
class AuthFailure extends Failure {
  const AuthFailure([String message = 'Lỗi xác thực.'])
      : super(message);
}

// Bạn có thể thêm các loại Failure khác nếu cần, ví dụ:
// class CacheFailure extends Failure {
//   const CacheFailure([String message = 'Lỗi bộ nhớ đệm.']) : super(message);
// }