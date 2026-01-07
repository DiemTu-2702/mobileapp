import 'package:flutter/material.dart';
import '../../../stats/presentation/widgets/test_stats_view.dart';
import '../../../stats/presentation/widgets/vocab_stats_view.dart';

class StatsScreen extends StatefulWidget {
  final String userId;

  const StatsScreen({super.key, required this.userId});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // 0: Luyện Thi, 1: Từ vựng
  int _selectedIndex = 0;

  // 👇 DÁN KEY GEMINI CỦA BẠN VÀO ĐÂY
  // Key này sẽ được truyền xuống cho TestStatsView dùng
  static const String _apiKey = 'DÁN_KEY_GEMINI_CỦA_BẠN_VÀO_ĐÂY';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trung tâm Thống kê"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4)
                ],
              ),
              child: Row(
                children: [
                  _buildToggleButton("Luyện Thi", 0),
                  _buildToggleButton("Học Từ Vựng", 1),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // --- 2. NỘI DUNG CHÍNH  ---
          Expanded(
            child: _selectedIndex == 0
                ? TestStatsView(userId: widget.userId, apiKey: _apiKey)
                : const VocabStatsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String title, int index) {
    final bool isSelected = _selectedIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue[800] : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}