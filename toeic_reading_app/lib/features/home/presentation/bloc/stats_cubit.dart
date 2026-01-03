import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../test_reading/data/models/test_history_model.dart';

// States
abstract class StatsState {}
class StatsLoading extends StatsState {}
class StatsLoaded extends StatsState {
  final List<TestHistoryModel> historyList;
  final double averageScore;
  final int highestScore;
  final int totalTests;

  StatsLoaded({
    required this.historyList,
    required this.averageScore,
    required this.highestScore,
    required this.totalTests,
  });
}
class StatsError extends StatsState {
  final String message;
  StatsError(this.message);
}

// Cubit
class StatsCubit extends Cubit<StatsState> {
  StatsCubit() : super(StatsLoading());

  Future<void> loadStats(String userId) async {
    print("--- BẮT ĐẦU TẢI THỐNG KÊ CHO USER: $userId ---");
    try {
      emit(StatsLoading());

      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('history')
          .orderBy('timestamp', descending: false) // Cũ nhất -> Mới nhất
          .get();

      print("--- TÌM THẤY ${snapshot.docs.length} BÀI LÀM ---");

      if (snapshot.docs.isEmpty) {
        emit(StatsLoaded(historyList: [], averageScore: 0, highestScore: 0, totalTests: 0));
        return;
      }

      List<TestHistoryModel> list = [];
      int totalScore = 0;
      int maxScore = 0;

      for (var doc in snapshot.docs) {
        try {
          // Log dữ liệu thô để debug
          print("Data: ${doc.data()}");
          final item = TestHistoryModel.fromSnapshot(doc);
          list.add(item);

          totalScore += item.score;
          if (item.score > maxScore) maxScore = item.score;
        } catch (e) {
          print("LỖI KHI PARSE DATA: $e");
        }
      }

      double avg = list.isNotEmpty ? totalScore / list.length : 0;

      emit(StatsLoaded(
        historyList: list,
        averageScore: avg,
        highestScore: maxScore,
        totalTests: list.length,
      ));
    } catch (e) {
      print("LỖI CHUNG: $e");
      emit(StatsError("Lỗi tải thống kê: $e"));
    }
  }
}