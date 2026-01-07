import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/question_entity.dart';
import '../../data/models/question_model.dart';
import '../../../../core/utils/score_calculator.dart';

// Kết nối với 2 file con (Event và State)
part 'test_work_event.dart';
part 'test_work_state.dart';

class TestWorkBloc extends Bloc<TestWorkEvent, TestWorkState> {
  Timer? _timer;
  List<QuestionEntity> _questions = [];

  TestWorkBloc() : super(TestLoading()) {
    on<StartTestEvent>(_onStartTest);
    on<SelectAnswerEvent>(_onSelectAnswer);
    on<SubmitTestEvent>(_onSubmitTest);

    // 👇 Đăng ký sự kiện TimerTicked
    on<TimerTicked>(_onTimerTicked);
  }

  Future<void> _onStartTest(StartTestEvent event, Emitter<TestWorkState> emit) async {
    emit(TestLoading());
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tests')
          .doc(event.testId)
          .collection('questions')
          .get();

      _questions = snapshot.docs.map((doc) {
        return QuestionModel.fromSnapshot(doc);
      }).toList();

      if (event.filterPart != null) {
        _questions = _questions.where((q) => q.part == event.filterPart).toList();
      }

      // Khởi tạo thời gian (Tính bằng giây)
      int remainingSeconds = event.minutes * 60;

      // Emit trạng thái ban đầu
      emit(TestInProgress(
          questions: List.from(_questions),
          remainingSeconds: remainingSeconds
      ));

      // 👇 LOGIC TIMER CHUẨN: Dùng biến cục bộ để đếm và add Event
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        remainingSeconds--; // Trừ thời gian

        if (remainingSeconds >= 0) {
          // Thay vì emit trực tiếp (gây lỗi), ta bắn sự kiện TimerTicked
          add(TimerTicked(remainingSeconds));
        } else {
          timer.cancel();
          // Hết giờ -> Tự động nộp bài
          add(SubmitTestEvent(event.testId, "Hết giờ"));
        }
      });

    } catch (e) {
      emit(TestError("Lỗi tải đề thi: $e"));
    }
  }

  // 👇 HÀM XỬ LÝ SỰ KIỆN TIMER TICKED (CẬP NHẬT UI)
  void _onTimerTicked(TimerTicked event, Emitter<TestWorkState> emit) {
    if (state is TestInProgress) {
      final currentState = state as TestInProgress;
      // Cập nhật số giây mới, giữ nguyên danh sách câu hỏi
      emit(currentState.copyWith(remainingSeconds: event.duration));
    }
  }

  void _onSelectAnswer(SelectAnswerEvent event, Emitter<TestWorkState> emit) {
    if (state is TestInProgress) {
      final currentState = state as TestInProgress;

      final updatedQuestions = currentState.questions.map((q) {
        if (q.id == event.questionId) {
          return q.copyWith(selectedIndex: event.answerIndex);
        }
        return q;
      }).toList();

      emit(TestInProgress(
        questions: updatedQuestions,
        remainingSeconds: currentState.remainingSeconds,
      ));
    }
  }

  Future<void> _onSubmitTest(SubmitTestEvent event, Emitter<TestWorkState> emit) async {
    if (state is TestInProgress) {
      final currentState = state as TestInProgress;
      _timer?.cancel(); // Dừng đồng hồ

      int correctCount = 0;
      Map<String, int?> userAnswers = {};

      for (var q in currentState.questions) {
        userAnswers[q.id] = q.selectedIndex;
        if (q.selectedIndex == q.correctIndex) {
          correctCount++;
        }
      }

      int finalScore = 0;
      int totalQuestions = currentState.questions.length;

      // Tính điểm (Logic này tùy thuộc vào app của bạn)
      if (totalQuestions > 0) {
        // Ví dụ đơn giản: (Số câu đúng / Tổng câu) * 100 hoặc dùng ScoreCalculator
        // Ở đây tôi dùng ScoreCalculator như code cũ của bạn
        finalScore = ScoreCalculator.getReadingScore(correctCount);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('history')
            .add({
          'testId': event.testId,
          'testTitle': event.testTitle,
          'score': finalScore,
          'correctCount': correctCount,
          'totalQuestions': totalQuestions,
          'timestamp': FieldValue.serverTimestamp(),
          'userAnswers': userAnswers,
        });
      }

      emit(TestSubmitted(
        score: finalScore,
        correctAnswers: correctCount,
        totalQuestions: totalQuestions,
        testId: event.testId,
      ));
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}