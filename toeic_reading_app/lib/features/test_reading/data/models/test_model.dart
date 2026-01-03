import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/test_entity.dart';
// import 'question_model.dart'; // Tạm thời chưa cần dùng khi load danh sách

class TestModel extends TestEntity {
  const TestModel({
    required super.id,
    required super.title,
    required super.description,      // <--- Mới
    required super.timeLimitMinutes,
    required super.totalQuestions,
    required super.imageUrl,         // <--- Mới
    super.questions,                 // Có thể null hoặc rỗng
  });

  // --- FACTORY CHO FIRESTORE ---
  // Dùng để chuyển đổi từ DocumentSnapshot sang TestModel
  factory TestModel.fromSnapshot(DocumentSnapshot doc) {
    // Ép kiểu dữ liệu lấy từ Firestore
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TestModel(
      id: doc.id, // Lấy ID thực của document (Auto-ID)

      title: data['title'] ?? 'Bài thi không tên',

      description: data['description'] ?? '',

      // Firestore lưu số dưới dạng num, cần ép sang int
      timeLimitMinutes: (data['timeLimitMinutes'] ?? 0) as int,

      totalQuestions: (data['totalQuestions'] ?? 0) as int,

      imageUrl: data['imageUrl'] ?? '',

      // Khi lấy danh sách bài thi bên ngoài, ta chưa cần lấy chi tiết câu hỏi
      // Nên trả về list rỗng để tiết kiệm và tránh lỗi nếu field này chưa có.
      questions: const [],
    );
  }

  // Nếu bạn muốn giữ fromJson cũ để dùng cho việc khác (optional)
  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      timeLimitMinutes: json['timeLimitMinutes'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
      questions: const [],
    );
  }
}