import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../test_reading/data/models/test_history_model.dart';

// --- IMPORT TÍNH NĂNG AI ---
import '../../../ai_tutor/presentation/bloc/ai_bloc.dart';
import '../../../ai_tutor/presentation/bloc/ai_event.dart';
import '../../../ai_tutor/presentation/widgets/ai_explanation_sheet.dart';
import '../../../ai_tutor/presentation/widgets/full_test_analysis_card.dart';

class HistoryDetailScreen extends StatefulWidget {
  final TestHistoryModel history;

  const HistoryDetailScreen({super.key, required this.history});

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  List<Map<String, dynamic>> _fullQuestions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOriginalQuestions();
  }

  // 👇 HÀM HỖ TRỢ: Lấy số thứ tự từ đề bài (Ví dụ: "101. Hello" -> trả về 101)
  int _extractQuestionNumber(String text) {
    try {
      final regex = RegExp(r'^(\d+)'); // Tìm số ở đầu dòng
      final match = regex.firstMatch(text.trim());
      if (match != null) return int.parse(match.group(1)!);
    } catch (_) {}
    return 9999; // Nếu không tìm thấy số thì đẩy xuống cuối
  }

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

      // 1. Lấy dữ liệu và map ID
      List<Map<String, dynamic>> allQuestions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).where((q) => widget.history.userAnswers.containsKey(q['id'])).toList();

      // 2. 👇 SẮP XẾP LẠI THEO SỐ CÂU HỎI
      allQuestions.sort((a, b) {
        // Cách 1: Nếu trong Firestore có lưu trường 'questionNumber' hoặc 'index'
        if (a.containsKey('questionNumber') && b.containsKey('questionNumber')) {
          return (a['questionNumber'] as int).compareTo(b['questionNumber'] as int);
        }

        // Cách 2: Parse số từ nội dung câu hỏi (VD: "101. The man...")
        int numA = _extractQuestionNumber(a['questionText'] ?? '');
        int numB = _extractQuestionNumber(b['questionText'] ?? '');
        return numA.compareTo(numB);
      });

      setState(() {
        _fullQuestions = allQuestions;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Lỗi tải đề gốc: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _analyzeFullTest(BuildContext context) {
    if (_fullQuestions.isEmpty) return;

    context.read<AiBloc>().add(AnalyzeFullTestEvent(
      score: widget.history.score,
      totalQuestions: widget.history.totalQuestions,
      fullQuestions: _fullQuestions,
      userAnswers: widget.history.userAnswers.cast<String, int?>(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    // Logic kiểm tra xem có phải Full Test hay không để hiện điểm số
    bool isShowScore = widget.history.testTitle.toLowerCase().contains("full");

    return Scaffold(
      appBar: AppBar(title: const Text("Chi tiết bài làm"), centerTitle: true),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER THỐNG KÊ ---
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
                  if (isShowScore) ...[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 100,
                          height: 100,
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
                  ] else ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        widget.history.testTitle,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],

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

            // 👇 CARD AI PHÂN TÍCH
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: FullTestAnalysisCard(
                onAnalyzePressed: () => _analyzeFullTest(context),
              ),
            ),

            const SizedBox(height: 10),

            // --- DANH SÁCH CÂU HỎI ---
            if (_fullQuestions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text("Không tải được nội dung câu hỏi gốc."),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _fullQuestions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 15),
                itemBuilder: (context, index) {
                  final qData = _fullQuestions[index];
                  final String qId = qData['id'];
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

// --- WIDGET CON: CHI TIẾT TỪNG CÂU HỎI ---
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

  void _openAiTutor(BuildContext context) {
    final q = widget.questionData;
    final options = q['options'] as List<dynamic>;
    final int correctIndex = q['correctIndex'] ?? 0;
    final int? userIndex = widget.userAnswerIndex;

    String correctAnswerText = options.length > correctIndex ? options[correctIndex] : "N/A";
    String userAnswerText = "Không trả lời";
    if (userIndex != null && userIndex < options.length) {
      userAnswerText = options[userIndex];
    }

    context.read<AiBloc>().add(AskAiEvent(
      question: q['questionText'] ?? "No text",
      userAnswer: userAnswerText,
      correctAnswer: correctAnswerText,
      options: options,
    ));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AiExplanationSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.questionData;
    final int correctIndex = q['correctIndex'] ?? 0;
    final int? userIndex = widget.userAnswerIndex;
    final List<dynamic> options = q['options'] ?? [];
    final String explanation = q['explanation'] ?? '';

    bool isCorrect = (userIndex == correctIndex);
    Color statusColor = isCorrect ? Colors.green : Colors.red;

    // 👇 Lấy số thứ tự từ nội dung câu hỏi để hiển thị đẹp hơn
    String questionText = q['questionText'] ?? '';
    RegExp regExp = RegExp(r'^(\d+)\.\s*');
    String displayQuestion = questionText;

    // Nếu text là "101. The man...", ta muốn hiển thị "Câu 101: The man..."
    // Nếu text không có số, ta dùng index + 1
    String labelPrefix = "Câu ${widget.index + 1}";

    if (regExp.hasMatch(questionText)) {
      var match = regExp.firstMatch(questionText);
      if (match != null) {
        String num = match.group(1)!;
        labelPrefix = "Câu $num";
        displayQuestion = questionText.substring(match.end); // Cắt bỏ số cũ đi cho đỡ trùng
      }
    }

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
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: "$labelPrefix: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        TextSpan(text: displayQuestion, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            ...List.generate(options.length, (i) {
              final String label = String.fromCharCode(65 + i);
              final String text = options[i].toString();

              Color? itemBg;
              Color itemText = widget.isDark ? Colors.white70 : Colors.black87;
              FontWeight weight = FontWeight.normal;

              if (i == correctIndex) {
                itemBg = Colors.green.withOpacity(0.15);
                itemText = Colors.green[800]!;
                if (widget.isDark) itemText = Colors.greenAccent;
                weight = FontWeight.bold;
              } else if (i == userIndex && !isCorrect) {
                itemBg = Colors.red.withOpacity(0.15);
                itemText = Colors.red[800]!;
                if (widget.isDark) itemText = Colors.redAccent;
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

            const SizedBox(height: 10),
            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _openAiTutor(context),
                  icon: const Icon(Icons.smart_toy, color: Colors.blueAccent),
                  label: const Text(
                    "Gia sư AI giải thích",
                    style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),

                if (explanation.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _showExplanation = !_showExplanation),
                    child: Row(
                      children: [
                        Text(
                          _showExplanation ? "Ẩn" : "Xem đáp án",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        Icon(
                          _showExplanation ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.grey,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            if (_showExplanation && explanation.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.grey[800] : Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(explanation),
              ),
          ],
        ),
      ),
    );
  }
}