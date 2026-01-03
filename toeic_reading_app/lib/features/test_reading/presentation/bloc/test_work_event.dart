part of 'test_work_bloc.dart';

abstract class TestWorkEvent extends Equatable {
  const TestWorkEvent();

  @override
  List<Object?> get props => [];
}

class StartTestEvent extends TestWorkEvent {
  final String testId;
  final int minutes;
  final int? filterPart;

  const StartTestEvent(this.testId, this.minutes, {this.filterPart});
}

class SelectAnswerEvent extends TestWorkEvent {
  final String questionId;
  final int answerIndex;

  const SelectAnswerEvent(this.questionId, this.answerIndex);
}

class SubmitTestEvent extends TestWorkEvent {
  final String testId;
  final String testTitle;

  const SubmitTestEvent(this.testId, this.testTitle);
}