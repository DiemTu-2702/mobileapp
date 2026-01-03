import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/test_entity.dart';
import '../../domain/entities/result_entity.dart';
import '../../domain/usecases/get_test_details_usecase.dart';
import '../../domain/usecases/submit_test_usecase.dart'; // <<< Sử dụng SubmitTestUseCase

part 'test_detail_event.dart'; // File này phải tồn tại
part 'test_detail_state.dart';  // File này phải tồn tại

class TestDetailBloc extends Bloc<TestDetailEvent, TestDetailState> {
  final GetTestDetailsUseCase getTestDetailsUseCase;
  final SubmitTestUseCase submitTestUseCase; // <<< Đã thêm

  TestDetailBloc({
    required this.getTestDetailsUseCase,
    required this.submitTestUseCase,
  }) : super(TestDetailInitial()) {
    on<LoadTestDetailsEvent>(_onLoadDetails);
    on<AnswerQuestionEvent>(_onAnswerQuestion);
    on<SubmitTestEvent>(_onSubmitTest); // <<< Đăng ký Handler nộp bài
  }

  // --- HANDLER: LOAD DETAILS ---
  Future<void> _onLoadDetails(LoadTestDetailsEvent event, Emitter<TestDetailState> emit) async {
    emit(TestDetailLoading());

    final result = await getTestDetailsUseCase(event.testId);

    result.fold(
          (failure) {
        emit(TestDetailError('Không thể tải chi tiết bài test.'));
      },
          (test) {
        // SỬA LỖI: Cung cấp remainingSeconds
        // Ta dùng timeLimitMinutes (phút) * 60 để chuyển sang giây
        final initialSeconds = test.timeLimitMinutes * 60;

        emit(
            TestDetailReady(
              test: test,
              remainingSeconds: initialSeconds, // <<< ĐÃ THÊM THAM SỐ
            )
        );
      },
    );
  }

  // --- HANDLER: ANSWER QUESTION ---
  void _onAnswerQuestion(AnswerQuestionEvent event, Emitter<TestDetailState> emit) {
    if (state is TestDetailReady) {
      final currentState = state as TestDetailReady;

      // Cập nhật đáp án
      final newAnswers = Map<String, int>.from(currentState.userAnswers);
      newAnswers[event.questionId] = event.answerIndex;

      emit(currentState.copyWith(userAnswers: newAnswers));
    }
  }

  // --- HANDLER: SUBMIT TEST (Nộp bài) ---
  Future<void> _onSubmitTest(SubmitTestEvent event, Emitter<TestDetailState> emit) async {
    if (state is TestDetailReady) {
      final currentState = state as TestDetailReady;
      emit(TestDetailSubmitting()); // Chuyển sang trạng thái đang nộp

      // **LOGIC TÍNH THỜI GIAN/CHẤM ĐIỂM SẼ NẰM TRONG USECASE**

      // Giả lập thời gian làm bài (Cần thay bằng logic thực tế)
      const mockTimeSpentSeconds = 600;

      final result = await submitTestUseCase(
        testId: currentState.test.id,
        testDetails: currentState.test,
        userAnswers: currentState.userAnswers,
        timeSpentSeconds: mockTimeSpentSeconds,
      );

      result.fold(
            (failure) {
          emit(TestDetailError('Nộp bài thất bại. Vui lòng thử lại.'));
        },
            (resultEntity) {
          emit(TestDetailResult(resultEntity)); // Chuyển sang màn hình kết quả
        },
      );
    }
  }
}