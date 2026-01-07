import 'package:google_generative_ai/google_generative_ai.dart';

class AiRemoteDataSource {
  static const String _apiKey = 'dán API AI ở đây';

  Future<String> getExplanation({
    required String question,
    required String userAnswer,
    required String correctAnswer,
    required String options,
  }) async {
    try {
      // --- CẬP NHẬT: Sử dụng model  ---
      final model = GenerativeModel(
        model: 'gemini-2.0-flash-exp',
        apiKey: _apiKey,
      );

      // 2. Tạo câu lệnh (Prompt)
      final prompt = '''
      Bạn là một gia sư TOEIC chuyên nghiệp, vui tính. Hãy giải thích câu hỏi sau:
      
      - Câu hỏi: "$question"
      - Các lựa chọn: $options
      - Người dùng chọn: "$userAnswer"
      - Đáp án đúng: "$correctAnswer"

      Yêu cầu trả lời:
      1. Nhận xét người dùng chọn đúng hay sai (nếu sai thì động viên nhẹ).
      2. Giải thích chi tiết tại sao đáp án đúng lại đúng (phân tích ngữ pháp, từ vựng, ngữ cảnh).
      3. Giải thích tại sao các đáp án còn lại là sai (nếu cần thiết).
      4. Dịch câu hỏi sang tiếng Việt.
      5. "Mẹo nhớ nhanh" (Tip) cho dạng bài này.
      6. Trình bày ngắn gọn, sử dụng emoji cho sinh động, dùng Markdown (in đậm) cho các từ khóa quan trọng.
      ''';

      // 3. Gửi yêu cầu
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      // 4. Trả về kết quả
      return response.text ?? "Gia sư AI đang suy nghĩ, bạn thử lại chút nữa nhé!";
    } catch (e) {
      return "Không thể kết nối với Gia sư AI. Lỗi: $e";
    }
  }
}