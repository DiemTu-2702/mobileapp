import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../test_reading/data/models/test_history_model.dart';

class HistoryDetailScreen extends StatefulWidget {
  final TestHistoryModel history;

  const HistoryDetailScreen({super.key, required this.history});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  // Biến lưu danh sách câu hỏi đầy đủ (có đề bài, giải thích)
  List<Map<String, dynamic>> _fullQuestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOriginalQuestions();
  }

  // HÀM QUAN TRỌNG: Tải lại nội dung câu hỏi từ Firestore dựa vào testId
  Future<void> _fetchOriginalQuestions() async {
    if (widget.history.testId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tests')
          .doc(widget.history.testId)
          .collection('questions')
          .get();

      // Lọc ra các câu hỏi mà user đã làm (có trong userAnswers)
      // Để tránh trường hợp làm Part 5 nhưng load cả câu hỏi Part 7
      final allQuestions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Lưu lại ID để đối chiếu
        return data;
      }).where((q) => widget.history.userAnswers.containsKey(q['id'])).toList();

      setState(() {
        _fullQuestions = allQuestions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi tải đề gốc: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết bài làm"), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER ĐIỂM SỐ ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 100, height: 100,
                        child: CircularProgressIndicator(
                          value: widget.history.score / 495,
                          strokeWidth: 8,
                          color: widget.history.score >= 250 ? Colors.green : Colors.orange,
                          backgroundColor: Colors.grey[200],
                        ),
                      ),
                      Column(
                        children: [
                          Text("${widget.history.score}", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                          const Text("Điểm số", style: TextStyle(fontSize: 12)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem("Đúng", "${widget.history.correctAnswers}", Colors.green),
                      _buildStatItem("Sai/Bỏ", "${widget.history.totalQuestions - widget.history.correctAnswers}", Colors.red),
                      _buildStatItem("Tổng", "${widget.history.totalQuestions}", Colors.blue),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // --- DANH SÁCH CÂU HỎI CHI TIẾT ---
            if (_fullQuestions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Không tải được nội dung câu hỏi gốc (Có thể đề thi đã bị xóa)."),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: _fullQuestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final qData = _fullQuestions[index];
                  final String qId = qData['id'];

                  // Lấy đáp án người dùng chọn từ Map userAnswers
                  final int? userIndex = widget.history.userAnswers[qId];

                  return _QuestionDetailCard(
                    index: index,
                    questionData: qData,
                    userAnswerIndex: userIndex,
                    isDark: isDark,
                  );
                },
              ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// Widget hiển thị từng câu hỏi
class _QuestionDetailCard extends StatefulWidget {
  final int index;
  final Map<String, dynamic> questionData;
  final int? userAnswerIndex;
  final bool isDark;

  const _QuestionDetailCard({
    required this.index,
    required this.questionData,
    required this.userAnswerIndex,
    required this.isDark,
  });

  @override
  State<_QuestionDetailCard> createState() => _QuestionDetailCardState();
}

class _QuestionDetailCardState extends State<_QuestionDetailCard> {
  bool _showExplanation = false;

  @override
  Widget build(BuildContext context) {
    final q = widget.questionData;
    final int correctIndex = q['correctIndex'] ?? 0; // Index đáp án đúng
    final int? userIndex = widget.userAnswerIndex;
    final List<dynamic> options = q['options'] ?? [];
    final String explanation = q['explanation'] ?? '';

    bool isCorrect = (userIndex == correctIndex);
    Color statusColor = isCorrect ? Colors.green : Colors.red;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Đề bài
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isCorrect ? Icons.check_circle : Icons.cancel,
                  color: statusColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Câu ${widget.index + 1}: ${q['questionText'] ?? ''}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Các đáp án
            ...List.generate(options.length, (i) {
              final String label = String.fromCharCode(65 + i);
              final String text = options[i].toString();

              // Logic màu sắc
              Color? itemBg;
              Color itemText = widget.isDark ? Colors.white70 : Colors.black87;
              FontWeight weight = FontWeight.normal;

              if (i == correctIndex) {
                // Đáp án ĐÚNG -> Xanh
                itemBg = Colors.green.withOpacity(0.15);
                itemText = Colors.green[800]!;
                if(widget.isDark) itemText = Colors.greenAccent;
                weight = FontWeight.bold;
              } else if (i == userIndex && !isCorrect) {
                // Đáp án CHỌN SAI -> Đỏ
                itemBg = Colors.red.withOpacity(0.15);
                itemText = Colors.red[800]!;
                if(widget.isDark) itemText = Colors.redAccent;
                weight = FontWeight.bold;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: itemBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Text("$label. ", style: TextStyle(fontWeight: FontWeight.bold, color: itemText)),
                    Expanded(child: Text(text, style: TextStyle(color: itemText, fontWeight: weight))),
                  ],
                ),
              );
            }),

            // Nút xem giải thích (chỉ hiện nếu có giải thích)
            if (explanation.isNotEmpty) ...[
              const Divider(height: 20),
              GestureDetector(
                onTap: () => setState(() => _showExplanation = !_showExplanation),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb, size: 18, color: Colors.amber[700]),
                    const SizedBox(width: 5),
                    Text(
                      _showExplanation ? "Ẩn giải thích" : "Xem giải thích chi tiết",
                      style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    Icon(_showExplanation ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
              if (_showExplanation)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.isDark ? Colors.grey[800] : Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(explanation),
                ),
            ]
          ],
        ),
      ),
    );
  }
}