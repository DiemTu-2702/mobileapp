import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/ai_remote_datasource.dart';
import 'ai_event.dart';
import 'ai_state.dart';

class AiBloc extends Bloc<AiEvent, AiState> {
  final AiRemoteDataSource dataSource;

  AiBloc({required this.dataSource}) : super(AiInitial()) {
    on<AskAiEvent>((event, emit) async {
      emit(AiLoading());
      try {
        String optionsStr = event.options.join(", ");
        final result = await dataSource.getExplanation(
          question: event.question,
          userAnswer: event.userAnswer,
          correctAnswer: event.correctAnswer,
          options: optionsStr,
        );
        emit(AiLoaded(result));
      } catch (e) {
        emit(AiError(e.toString()));
      }
    });

    on<AnalyzeFullTestEvent>(_onAnalyzeFullTest);
  }

  Future<void> _onAnalyzeFullTest(
      AnalyzeFullTestEvent event, Emitter<AiState> emit) async {
    emit(AiLoading());
    try {
      // BƯỚC 1: Lọc ra danh sách các câu làm SAI hoặc BỎ TRỐNG
      List<Map<String, dynamic>> wrongQuestions = [];

      for (var q in event.fullQuestions) {
        String qId = q['id'];
        int correctIndex = q['correctIndex'] ?? 0;
        int? userIndex = event.userAnswers[qId];

        if (userIndex != correctIndex) {
          List<dynamic> opts = q['options'] ?? [];
          String userAnsText = (userIndex != null && userIndex < opts.length)
              ? opts[userIndex]
              : "Bỏ trống";
          String correctAnsText =
          (opts.isNotEmpty && correctIndex < opts.length)
              ? opts[correctIndex]
              : "N/A";

          wrongQuestions.add({
            'index': event.fullQuestions.indexOf(q) + 1,
            'text': q['questionText'],
            'userAns': userAnsText,
            'correctAns': correctAnsText,
          });
        }
      }

      // BƯỚC 2: Tạo Prompt (Câu lệnh) chi tiết cho AI
      // Giới hạn gửi tối đa 15 câu sai điển hình để tránh quá tải token
      final limitedWrongs = wrongQuestions.take(15).toList();

      StringBuffer promptBuffer = StringBuffer();
      promptBuffer.writeln("Bạn là chuyên gia TOEIC. Hãy phân tích kết quả bài thi sau:");
      // promptBuffer.writeln("- Điểm số: ${event.score}/990.");
      promptBuffer.writeln("- Số câu đúng: ${event.totalQuestions - wrongQuestions.length}/${event.totalQuestions}.");
      promptBuffer.writeln("\nDanh sách các câu sai điển hình (tôi gửi mẫu ${limitedWrongs.length} câu):");

      for (var w in limitedWrongs) {
        promptBuffer.writeln("- Câu ${w['index']}: ${w['text']}");
        promptBuffer.writeln("  + Chọn: ${w['userAns']} | Đúng: ${w['correctAns']}");
      }

      promptBuffer.writeln("\n\n=== YÊU CẦU PHÂN TÍCH CHI TIẾT ===");
      promptBuffer.writeln("1. **Nhận xét chung:** Đánh giá ngắn gọn phong độ.");
      promptBuffer.writeln("2. **Phân tích Ngữ Pháp (Part 5/6):**");
      promptBuffer.writeln("   - Nếu câu sai thuộc về 'Thì' (Tenses): Hãy chỉ rõ câu số mấy sai, sai thì gì. BẮT BUỘC hiện CÔNG THỨC và CÁCH DÙNG của thì đó để ôn tập.");
      promptBuffer.writeln("   - Nếu sai Từ loại/Giới từ: Giải thích ngắn gọn.");
      promptBuffer.writeln("3. **Phân tích Đọc Hiểu (Part 7):**");
      promptBuffer.writeln("   - Phân tích xem người học sai do không tìm thấy thông tin hay do bẫy từ vựng.");
      promptBuffer.writeln("   - Đề xuất 3 chủ đề TỪ VỰNG hoặc cụm từ trong bài cần học ngay để khắc phục.");
      promptBuffer.writeln("4. **Lời khuyên:** 1 tips cụ thể cho lần sau.");
      promptBuffer.writeln("Hãy trình bày định dạng Markdown, dễ đọc, giọng văn khuyến khích.");

      // BƯỚC 3: Gửi prompt qua DataSource
      // Chúng ta tái sử dụng hàm getExplanation, truyền Prompt vào tham số 'question'
      // Các tham số khác để trống vì Prompt đã bao gồm tất cả thông tin
      final result = await dataSource.getExplanation(
        question: promptBuffer.toString(),
        userAnswer: "Analysis Request",
        correctAnswer: "N/A",
        options: "",
      );

      emit(AiLoaded(result));
    } catch (e) {
      emit(AiError("Lỗi phân tích: $e"));
    }
  }
}