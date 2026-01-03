part of 'test_list_bloc.dart';

abstract class TestListState extends Equatable {
  const TestListState();
  @override
  List<Object> get props => [];
}

class TestListInitial extends TestListState {}
class TestListLoading extends TestListState {}

class TestListLoaded extends TestListState {
  final List<TestEntity> tests;
  const TestListLoaded(this.tests);

  @override
  List<Object> get props => [tests];
}

class TestListError extends TestListState {
  final String message;
  const TestListError(this.message);

  @override
  List<Object> get props => [message];
}