part of 'test_detail_bloc.dart';

abstract class TestDetailEvent extends Equatable {
  const TestDetailEvent();
  @override
  List<Object> get props => [];
}

// 1. Yêu cầu tải chi tiết bài test (Khi màn hình được mở)
class LoadTestDetailsEvent extends TestDetailEvent {
  final String testId;
  const LoadTestDetailsEvent(this.testId);
  @override
  List<Object> get props => [testId];
}

// 2. Người dùng chọn/thay đổi đáp án
class AnswerQuestionEvent extends TestDetailEvent {
  final String questionId;
  final int answerIndex;
  const AnswerQuestionEvent({required this.questionId, required this.answerIndex});
  @override
  List<Object> get props => [questionId, answerIndex];
}

// 3. Người dùng nộp bài
class SubmitTestEvent extends TestDetailEvent {}

// 4. (Tùy chọn) Sự kiện cập nhật bộ đếm thời gian
class UpdateTimerEvent extends TestDetailEvent {}