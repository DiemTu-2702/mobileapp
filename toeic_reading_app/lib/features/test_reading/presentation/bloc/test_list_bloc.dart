import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/test_entity.dart';
import '../../domain/usecases/get_available_tests_usecase.dart';

part 'test_list_event.dart';
part 'test_list_state.dart';

class TestListBloc extends Bloc<TestListEvent, TestListState> {
  final GetAvailableTestsUseCase getAvailableTestsUseCase;

  TestListBloc({required this.getAvailableTestsUseCase}) : super(TestListInitial()) {
    on<FetchTestsEvent>(_onFetchTests);
  }

  Future<void> _onFetchTests(FetchTestsEvent event, Emitter<TestListState> emit) async {
    emit(TestListLoading());

    final result = await getAvailableTestsUseCase();

    result.fold(
          (failure) {
        emit(TestListError(_mapFailureToMessage(failure)));
      },
          (tests) {
        emit(TestListLoaded(tests));
      },
    );
  }

  // Có thể dùng hàm này chung với AuthBloc
  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) {
      return 'Không thể tải danh sách bài thi. Vui lòng kiểm tra kết nối.';
    } else {
      return 'Lỗi không xác định.';
    }
  }
}