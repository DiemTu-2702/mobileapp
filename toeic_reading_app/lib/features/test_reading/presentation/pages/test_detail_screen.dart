import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'test_work_screen.dart'; // Import màn hình làm bài

class TestDetailScreen extends StatelessWidget {
  final String testId;
  final int? filterPart; // Biến lọc Part (5, 6, hoặc 7)

  const TestDetailScreen({
    super.key,
    required this.testId,
    this.filterPart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết bài thi'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('tests').doc(testId).get(),
        builder: (context, snapshot) {
          // 1. Đang tải
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Lỗi hoặc không có dữ liệu
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Không tìm thấy thông tin bài thi"));
          }

          // 3. Xử lý dữ liệu
          final data = snapshot.data!.data() as Map<String, dynamic>;
          String title = data['title'] ?? 'Bài thi không tên';
          String description = data['description'] ?? 'Không có mô tả';
          int timeLimit = data['timeLimitMinutes'] ?? 75;
          int totalQuestions = data['totalQuestions'] ?? 100;

          // --- LOGIC XỬ LÝ KHI CHỌN LÀM RIÊNG PART ---
          if (filterPart != null) {
            // Cập nhật tiêu đề
            title = "$title - Part $filterPart";

            // Cập nhật thời gian và số câu (Ước lượng chuẩn TOEIC)
            if (filterPart == 5) {
              timeLimit = 12; // Part 5 thường làm trong 10-15p
              totalQuestions = 30;
            } else if (filterPart == 6) {
              timeLimit = 10; // Part 6 thường làm trong 8-10p
              totalQuestions = 16;
            } else if (filterPart == 7) {
              timeLimit = 55; // Part 7 dài nhất
              totalQuestions = 54;
            }
          }
          // ---------------------------------------------

          return Column(
            children: [
              // --- PHẦN 1: NỘI DUNG CUỘN ---
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon trang trí
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.menu_book, size: 60, color: Colors.blue[800]),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // Tên bài thi
                      Center(
                        child: Text(
                          title,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Thông số (Thời gian - Số câu)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildInfoChip(Icons.timer, "$timeLimit phút"),
                          const SizedBox(width: 15),
                          _buildInfoChip(Icons.list_alt, "$totalQuestions câu hỏi"),
                        ],
                      ),
                      const SizedBox(height: 30),

                      const Divider(),
                      const SizedBox(height: 10),

                      // Mô tả
                      const Text(
                        "Hướng dẫn làm bài:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        filterPart != null
                            ? "Bạn đang chọn chế độ luyện tập riêng Part $filterPart. Hệ thống sẽ chỉ lọc ra các câu hỏi thuộc phần này."
                            : description,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "- Đồng hồ sẽ đếm ngược ngay khi bạn ấn Bắt đầu.\n"
                            "- Bạn có thể nộp bài bất cứ lúc nào.",
                        style: TextStyle(fontSize: 15, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

              // --- PHẦN 2: NÚT START ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        // CHUYỂN MÀN HÌNH VÀ TRUYỀN BIẾN filterPart
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TestWorkScreen(
                              testId: testId,
                              testTitle: title,
                              minutes: timeLimit,
                              // Truyền biến lọc Part sang màn hình làm bài
                              filterPart: filterPart,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                      ),
                      child: const Text(
                        'BẮT ĐẦU LÀM BÀI',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }
}