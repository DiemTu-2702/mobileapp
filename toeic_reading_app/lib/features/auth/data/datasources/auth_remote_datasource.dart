import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn(String email, String password);
  Future<UserModel> signUp(String email, String password, String name);
  Future<UserModel> checkAuthStatus();
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth authClient;
  final FirebaseFirestore firestore;

  AuthRemoteDataSourceImpl({required this.authClient, required this.firestore});

  // -------------------------------------------------------------------------
  // 0. SIGN OUT
  // -------------------------------------------------------------------------
  @override
  Future<void> signOut() async {
    await authClient.signOut();
  }

  // -------------------------------------------------------------------------
  // 1. SIGN IN (ĐĂNG NHẬP) - Lấy cả Name và Role
  // -------------------------------------------------------------------------
  @override
  Future<UserModel> signIn(String email, String password) async {
    try {
      // 1. Xác thực với Firebase Auth
      final credential = await authClient.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw ServerException(message: 'Lỗi đăng nhập: Không tìm thấy tài khoản.');
      }

      // 2. Lấy thông tin bổ sung (Name, Role) từ Firestore
      String userName = 'Người dùng';
      String userRole = 'user'; // Mặc định

      final userDoc = await firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data();
        userName = data?['name'] ?? 'Người dùng';
        userRole = data?['role'] ?? 'user'; // <--- LẤY ROLE
      }

      // 3. Trả về User Model đầy đủ
      return UserModel(
        id: user.uid,
        email: user.email ?? 'no-email',
        name: userName,
        role: userRole, // <--- TRUYỀN ROLE VÀO MODEL
        token: await user.getIdToken() ?? '',
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'Email hoặc mật khẩu không đúng.';
      } else {
        errorMessage = e.message ?? 'Đăng nhập thất bại.';
      }
      throw ServerException(message: errorMessage);
    } catch (e) {
      throw ServerException(message: 'Lỗi không xác định khi đăng nhập.');
    }
  }

  // -------------------------------------------------------------------------
  // 2. SIGN UP (ĐĂNG KÝ) - Lưu mặc định Role là 'user'
  // -------------------------------------------------------------------------
  @override
  Future<UserModel> signUp(String email, String password, String name) async {
    try {
      // 1. Tạo user trong Firebase Auth
      final credential = await authClient.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        throw ServerException(message: 'Lỗi đăng ký: Không tạo được tài khoản.');
      }

      // 2. Lưu thông tin vào Firestore (bao gồm Role)
      await firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': email,
        'name': name,
        'role': 'user', // <--- QUAN TRỌNG: Mặc định là user thường
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Trả về UserModel
      return UserModel(
        id: user.uid,
        email: user.email ?? 'no-email',
        name: name,
        role: 'user', // Trả về role mặc định ngay lập tức
        token: await user.getIdToken() ?? '',
      );

    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Địa chỉ email này đã được sử dụng.';
      } else {
        errorMessage = e.message ?? 'Đăng ký thất bại.';
      }
      throw ServerException(message: errorMessage);
    } catch (e) {
      throw ServerException(message: 'Lỗi không xác định khi đăng ký.');
    }
  }

  // -------------------------------------------------------------------------
  // 3. CHECK AUTH STATUS - Đã sửa lỗi biến Role/Name
  // -------------------------------------------------------------------------
  @override
  Future<UserModel> checkAuthStatus() async {
    final user = authClient.currentUser;

    if (user != null) {
      // Khai báo biến TRƯỚC khi dùng trong try/catch
      String userName = 'Người dùng';
      String userRole = 'user';

      try {
        final doc = await firestore.collection('users').doc(user.uid).get();

        if (doc.exists) {
          final data = doc.data();
          // Cập nhật giá trị cho biến đã khai báo
          userRole = data?['role'] ?? 'user';
          userName = data?['name'] ?? 'Người dùng';

          print("Admin Check: User ${user.email} - Role: $userRole");
        } else {
          print("Admin Check: Không tìm thấy data Firestore, dùng mặc định.");
        }
      } catch (e) {
        print("Lỗi khi lấy role từ Firestore: $e");
        // Nếu lỗi mạng, vẫn giữ giá trị mặc định 'user' để không crash app
      }

      // Trả về Model bằng factory constructor (đảm bảo UserModel có hỗ trợ role)
      return UserModel.fromFirebase(user, name: userName, role: userRole);
    } else {
      throw ServerException(message: 'Chưa đăng nhập');
    }
  }
}