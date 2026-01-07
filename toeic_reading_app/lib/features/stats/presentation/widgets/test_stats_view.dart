import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../home/presentation/bloc/stats_cubit.dart';
import '../../../test_reading/data/models/test_history_model.dart';

class TestStatsView extends StatelessWidget {
  final String userId;
  final String apiKey;

  const TestStatsView({super.key, required this.userId, required this.apiKey});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StatsCubit()..loadStats(userId),
      child: DefaultTabController(
        length: 4,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: const TabBar(
                isScrollable: false,
                indicatorColor: Colors.amber,
                indicatorWeight: 4,
                labelColor: Colors.blue,
                labelStyle: TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(text: "Part 5"),
                  Tab(text: "Part 6"),
                  Tab(text: "Part 7"),
                  Tab(text: "Full Test"),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<StatsCubit, StatsState>(
                builder: (context, state) {
                  if (state is StatsLoading) return const Center(child: CircularProgressIndicator());
                  if (state is StatsError) return Center(child: Text("Lỗi: ${state.message}"));
                  if (state is StatsLoaded) {
                    return TabBarView(
                      children: [
                        StatsTabContent(fullHistory: state.historyList, filterKeyword: "Part 5", isFullTest: false, apiKey: apiKey),
                        StatsTabContent(fullHistory: state.historyList, filterKeyword: "Part 6", isFullTest: false, apiKey: apiKey),
                        StatsTabContent(fullHistory: state.historyList, filterKeyword: "Part 7", isFullTest: false, apiKey: apiKey),
                        StatsTabContent(fullHistory: state.historyList, filterKeyword: "Full", isFullTest: true, apiKey: apiKey),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- WIDGET CON: HIỂN THỊ CHI TIẾT TỪNG TAB ---
class StatsTabContent extends StatefulWidget {
  final List<TestHistoryModel> fullHistory;
  final String filterKeyword;
  final bool isFullTest;
  final String apiKey;

  const StatsTabContent({
    super.key,
    required this.fullHistory,
    required this.filterKeyword,
    required this.isFullTest,
    required this.apiKey,
  });

  @override
  State<StatsTabContent> createState() => _StatsTabContentState();
}

class _StatsTabContentState extends State<StatsTabContent> {
  String? _aiAnalysis;
  bool _isAnalyzing = false;

  Future<void> _analyzePerformance(List<TestHistoryModel> filteredList) async {
    if (widget.apiKey.contains("DÁN_KEY") || widget.apiKey.isEmpty) {
      setState(() => _aiAnalysis = "Vui lòng nhập API Key trong code.");
      return;
    }

    setState(() => _isAnalyzing = true);
    try {
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: widget.apiKey);
      StringBuffer dataSummary = StringBuffer();
      dataSummary.writeln("Lịch sử làm bài ${widget.filterKeyword}:");
      final recentTests = filteredList.take(10).toList();
      double totalPercent = 0;
      int count = 0;

      for (var test in recentTests) {
        double score = widget.isFullTest ? test.score.toDouble() : test.correctAnswers.toDouble();
        double total = test.totalQuestions.toDouble();
        double percent = total > 0 ? (score / total * 100) : 0;
        dataSummary.writeln("- ${DateFormat('dd/MM').format(test.date)}: $score/$total (${percent.toStringAsFixed(1)}%)");
        totalPercent += percent;
        count++;
      }
      double avg = count > 0 ? totalPercent / count : 0;

      String prompt = """
      Bạn là chuyên gia TOEIC. Dữ liệu:
      ${dataSummary.toString()}
      Trung bình: ${avg.toStringAsFixed(1)}%.
      Hãy: 1. Đánh giá xu hướng. 2. Chỉ ra điểm yếu của ${widget.filterKeyword}. 3. Đưa ra 2 lời khuyên cải thiện cụ thể. 4. Dự đoán điểm sắp tới.
      Trả lời ngắn gọn, động viên.
      """;

      final response = await model.generateContent([Content.text(prompt)]);
      if (mounted) setState(() { _aiAnalysis = response.text; _isAnalyzing = false; });
    } catch (e) {
      if (mounted) setState(() { _aiAnalysis = "Lỗi kết nối AI: $e"; _isAnalyzing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = widget.fullHistory.where((item) => item.testTitle.contains(widget.filterKeyword)).toList();
    filteredList.sort((a, b) => a.date.compareTo(b.date));

    if (filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 15),
            Text("Chưa có dữ liệu cho ${widget.filterKeyword}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    double totalVal = 0;
    int maxVal = 0;
    for (var item in filteredList) {
      int val = widget.isFullTest ? item.score : item.correctAnswers;
      totalVal += val;
      if (val > maxVal) maxVal = val;
    }
    int avg = (filteredList.isNotEmpty) ? (totalVal / filteredList.length).ceil() : 0;

    String unit = widget.isFullTest ? "Điểm" : "Câu";
    double maxY = widget.isFullTest ? 990 : (filteredList.isNotEmpty ? filteredList[0].totalQuestions.toDouble() + 5 : 50);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- CARD AI ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.indigo.shade900, Colors.blue.shade600]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Row(children: [Icon(Icons.auto_awesome, color: Colors.amber), SizedBox(width: 8), Text("AI Phân Tích", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
                  if (!_isAnalyzing && _aiAnalysis == null)
                    ElevatedButton(
                      onPressed: () => _analyzePerformance(filteredList),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue, padding: const EdgeInsets.symmetric(horizontal: 10), minimumSize: const Size(0, 30)),
                      child: const Text("Phân tích", style: TextStyle(fontSize: 12)),
                    )
                ]),
                const SizedBox(height: 8),
                if (_isAnalyzing) const LinearProgressIndicator(color: Colors.amber, backgroundColor: Colors.white24)
                else if (_aiAnalysis != null) Text(_aiAnalysis!, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4))
                else const Text("Bấm nút để AI tìm điểm yếu và gợi ý lộ trình.", style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- CHỈ SỐ ---
          Row(children: [
            _buildStatCard("Trung bình", "$avg $unit", Colors.orange),
            const SizedBox(width: 10),
            _buildStatCard("Cao nhất", "$maxVal $unit", Colors.green),
            const SizedBox(width: 10),
            _buildStatCard("Số bài", "${filteredList.length}", Colors.blue),
          ]),

          const SizedBox(height: 30),
          Text(
            widget.isFullTest ? "📈 Biểu đồ điểm số" : "📈 Biểu đồ số câu đúng",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 15),

          // --- BIỂU ĐỒ ---
          Container(
            height: 350,
            padding: const EdgeInsets.fromLTRB(10, 25, 25, 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))],
            ),
            child: LineChart(_mainData(filteredList, maxY)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(title, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ]),
      ),
    );
  }

  LineChartData _mainData(List<TestHistoryModel> data, double maxYVal) {
    List<FlSpot> spots = [];
    for (int i = 0; i < data.length; i++) {
      double val = widget.isFullTest ? data[i].score.toDouble() : data[i].correctAnswers.toDouble();
      spots.add(FlSpot(i.toDouble(), val));
    }

    double maxX = (data.length - 1).toDouble();
    if (maxX <= 0) maxX = 1.0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: widget.isFullTest ? 50 : 5,
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
            interval: widget.isFullTest ? 100 : 5,
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