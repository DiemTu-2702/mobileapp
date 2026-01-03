import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    super.name,
    super.role,
    required super.token,
  });

  // Helper để tạo Model từ Auth + Dữ liệu Firestore (nếu có)
  factory UserModel.fromFirebase(dynamic user, {String? name, String? role}) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      name: name ?? user.displayName ?? 'Người dùng',
      role: role ?? 'user',
      token: '',
    );
  }
}