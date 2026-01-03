import 'package:flutter/material.dart';
import '../bloc/test_work_bloc.dart';

class ResultScreen extends StatelessWidget {
  final TestSubmitted state;

  const ResultScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // LOGIC KIỂM TRA:
    // Nếu tổng câu hỏi >= 100 (Chuẩn TOEIC Reading) -> Coi là Full Test -> Hiện điểm.
    // Ngược lại -> Coi là luyện tập Part -> Ẩn điểm, chỉ hiện câu đúng.
    final bool isFullTest = state.totalQuestions >= 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kết quả bài thi"),
        backgroundColor: Colors.blue[900],
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Chặn nút back
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
              const SizedBox(height: 20),
              const Text(
                  "Bạn đã hoàn thành!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 30),

              // 1. CHỈ HIỆN ĐIỂM SỐ NẾU LÀ FULL TEST
              if (isFullTest)
                _buildResultCard("Điểm số ", "${state.score}", Colors.blue),

              // 2. LUÔN HIỆN SỐ CÂU ĐÚNG
              _buildResultCard(
                  "Số câu đúng",
                  "${state.correctAnswers} / ${state.totalQuestions}",
                  Colors.green
              ),

              const SizedBox(height: 40),

              // Nút về trang chủ
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white
                  ),
                  onPressed: () {
                    // Quay về màn hình danh sách (Pop hết các màn hình trước đó)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: const Text("Về trang chủ", style: TextStyle(fontSize: 18)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String value, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
            Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)
            ),
          ],
        ),
      ),
    );
  }
}