import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/question_entity.dart';
import '../../data/models/question_model.dart';
import '../../../../core/utils/score_calculator.dart';

// Kết nối với 2 file con
part 'test_work_event.dart';
part 'test_work_state.dart';

class TestWorkBloc extends Bloc<TestWorkEvent, TestWorkState> {
  Timer? _timer;
  List<QuestionEntity> _questions = [];

  TestWorkBloc() : super(TestLoading()) {
    on<StartTestEvent>(_onStartTest);
    on<SelectAnswerEvent>(_onSelectAnswer);
    on<SubmitTestEvent>(_onSubmitTest);
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

      int remainingSeconds = event.minutes * 60;

      emit(TestInProgress(
          questions: List.from(_questions),
          remainingSeconds: remainingSeconds
      ));

      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (remainingSeconds > 0) {
          remainingSeconds--;
          // Nếu muốn update UI thời gian thực, cần thêm logic emit ở đây
        } else {
          timer.cancel();
          add(SubmitTestEvent(event.testId, "Hết giờ"));
        }
      });

    } catch (e) {
      emit(TestError("Lỗi tải đề thi: $e"));
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
      _timer?.cancel();

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

      if (totalQuestions >= 100) {
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