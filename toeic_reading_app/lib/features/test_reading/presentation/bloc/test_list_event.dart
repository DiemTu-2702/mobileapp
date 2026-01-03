part of 'test_list_bloc.dart';

abstract class TestListEvent extends Equatable {
  const TestListEvent();
  @override
  List<Object> get props => [];
}

// Yêu cầu tải danh sách bài test
class FetchTestsEvent extends TestListEvent {}