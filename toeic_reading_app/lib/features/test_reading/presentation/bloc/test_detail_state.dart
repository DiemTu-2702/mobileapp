part of 'test_detail_bloc.dart';

abstract class TestDetailState extends Equatable {
  const TestDetailState();
  @override
  List<Object> get props => [];
}

// 1. Trạng thái ban đầu
class TestDetailInitial extends TestDetailState {}

// 2. Trạng thái đang tải
class TestDetailLoading extends TestDetailState {}

// 3. Trạng thái sẵn sàng làm bài
class TestDetailReady extends TestDetailState {
  final TestEntity test;
  // Lưu đáp án tạm thời của người dùng {QuestionId: AnswerIndex}
  final Map<String, int> userAnswers;
  // Bộ đếm thời gian (giây)
  final int remainingSeconds;

  const TestDetailReady({
    required this.test,
    this.userAnswers = const {},
    required this.remainingSeconds,
  });

  @override
  List<Object> get props => [test, userAnswers, remainingSeconds];

  // Dùng để cập nhật đáp án hoặc thời gian mà không cần tải lại bài test
  TestDetailReady copyWith({
    Map<String, int>? userAnswers,
    int? remainingSeconds,
  }) {
    return TestDetailReady(
      test: test,
      userAnswers: userAnswers ?? this.userAnswers,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
    );
  }
}

// 4. Trạng thái đang nộp bài
class TestDetailSubmitting extends TestDetailState {}

// 5. Trạng thái kết quả đã được tính toán
class TestDetailResult extends TestDetailState {
  final ResultEntity result;
  const TestDetailResult(this.result);

  @override
  List<Object> get props => [result];
}

// 6. Trạng thái lỗi
class TestDetailError extends TestDetailState {
  final String message;
  const TestDetailError(this.message);
  @override
  List<Object> get props => [message];
}