import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/stats_cubit.dart';
import '../../../test_reading/data/models/test_history_model.dart';

class StatsScreen extends StatelessWidget {
  final String userId;

  const StatsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatsCubit()..loadStats(userId),
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Thống kê tiến độ"),
            backgroundColor: Colors.blue[800],
            foregroundColor: Colors.white,
            centerTitle: true,
            bottom: const TabBar(
              isScrollable: false,
              indicatorColor: Colors.amber,
              indicatorWeight: 4,
              labelColor: Colors.white,
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelColor: Colors.white60,
              tabs: [
                Tab(text: "Part 5"),
                Tab(text: "Part 6"),
                Tab(text: "Part 7"),
                Tab(text: "Full Test"),
              ],
            ),
          ),
          backgroundColor: Colors.grey[100],
          body: BlocBuilder<StatsCubit, StatsState>(
            builder: (context, state) {
              if (state is StatsLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is StatsError) {
                return Center(child: Text("Lỗi: ${state.message}"));
              }
              if (state is StatsLoaded) {
                return TabBarView(
                  children: [
                    _StatsTabContent(fullHistory: state.historyList, filterKeyword: "Part 5", isFullTest: false),
                    _StatsTabContent(fullHistory: state.historyList, filterKeyword: "Part 6", isFullTest: false),
                    _StatsTabContent(fullHistory: state.historyList, filterKeyword: "Part 7", isFullTest: false),
                    _StatsTabContent(fullHistory: state.historyList, filterKeyword: "Full", isFullTest: true),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }
}

class _StatsTabContent extends StatelessWidget {
  final List<TestHistoryModel> fullHistory;
  final String filterKeyword;
  final bool isFullTest;

  const _StatsTabContent({
    required this.fullHistory,
    required this.filterKeyword,
    required this.isFullTest,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Lọc dữ liệu
    final filteredList = fullHistory.where((item) {
      return item.testTitle.contains(filterKeyword);
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 15),
            Text("Chưa có dữ liệu cho $filterKeyword", style: const TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 10),
          ],
        ),
      );
    }

    // 2. Tính toán chỉ số
    double totalVal = 0;
    int maxVal = 0;

    for (var item in filteredList) {
      // Nếu là Full Test -> Lấy Score
      // Nếu là Part -> Lấy CorrectAnswers
      int valueToCalc = isFullTest ? item.score : item.correctAnswers;

      totalVal += valueToCalc;
      if (valueToCalc > maxVal) maxVal = valueToCalc;
    }

    // --- TÍNH TRUNG BÌNH VÀ LÀM TRÒN LÊN ---
    int averageRounded = 0;
    if (filteredList.isNotEmpty) {
      double rawAverage = totalVal / filteredList.length;
      averageRounded = rawAverage.ceil(); // Làm tròn lên (4.1 -> 5)
    }

    String unit = isFullTest ? "Điểm" : "Câu";
    String avgLabel = isFullTest ? "Điểm trung bình" : "Đúng trung bình";
    String maxLabel = isFullTest ? "Điểm cao nhất" : "Đúng nhiều nhất";
    double maxYChart = isFullTest ? 500 : (filteredList.isNotEmpty ? filteredList[0].totalQuestions.toDouble() + 5 : 50);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thẻ tổng quan
          Row(
            children: [
              _buildSummaryCard(avgLabel, "$averageRounded $unit", Colors.orange, Icons.pie_chart),
              const SizedBox(width: 10),
              _buildSummaryCard(maxLabel, "$maxVal $unit", Colors.green, Icons.emoji_events),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSummaryCard("Số bài đã làm", "${filteredList.length}", Colors.blue, Icons.assignment_turned_in),
            ],
          ),

          const SizedBox(height: 30),
          Text(
              isFullTest ? "📈 Biểu đồ điểm số" : "📈 Biểu đồ số câu đúng",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
          ),
          const SizedBox(height: 15),

          // Biểu đồ
          Container(
            height: 350,
            padding: const EdgeInsets.fromLTRB(10, 25, 25, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: filteredList.length < 2
                ? _buildNotEnoughDataMessage()
                : LineChart(_mainData(filteredList, maxYChart)),
          ),

          const SizedBox(height: 10),
          if (filteredList.length >= 2)
            const Center(child: Text("(Trục ngang: Lần làm bài  -  Trục dọc: Kết quả)", style: TextStyle(fontSize: 12, color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildNotEnoughDataMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 50, color: Colors.blue[100]),
          const SizedBox(height: 10),
          const Text("Cần ít nhất 2 bài làm để vẽ biểu đồ.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: color.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  LineChartData _mainData(List<TestHistoryModel> data, double maxYVal) {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      double val = isFullTest ? data[i].score.toDouble() : data[i].correctAnswers.toDouble();
      spots.add(FlSpot(i.toDouble(), val));
    }

    double maxX = (data.length - 1).toDouble();
    if (maxX <= 0) maxX = 1.0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: isFullTest ? 50 : 5,
        getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              int index = value.toInt();
              if (index >= 0 && index < data.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('d/M').format(data[index].date),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: isFullTest ? 100 : 5,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(value.toInt().toString(), style: const TextStyle(fontSize: 10, color: Colors.grey));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: Colors.black12)),
      minX: 0,
      maxX: maxX,
      minY: 0,
      maxY: maxYVal,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.red,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.1)),
        ),
      ],
    );
  }
}