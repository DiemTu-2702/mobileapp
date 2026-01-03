import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/test_work_bloc.dart';
import '../../domain/entities/question_entity.dart';
import 'result_screen.dart';

class TestWorkScreen extends StatefulWidget {
  final String testId;
  final String testTitle;
  final int minutes;
  final int? filterPart;

  const TestWorkScreen({
    super.key,
    required this.testId,
    required this.testTitle,
    required this.minutes,
    this.filterPart,
  });

  @override
  State<TestWorkScreen> createState() => _TestWorkScreenState();
}

class _TestWorkScreenState extends State<TestWorkScreen> {
  final PageController _pageController = PageController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // Key để mở Drawer
  int _currentGroupIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }

  // --- LOGIC XỬ LÝ SỐ CÂU HỎI ---
  int _extractQuestionNumber(String text) {
    try {
      final regex = RegExp(r'^(\d+)');
      final match = regex.firstMatch(text.trim());
      if (match != null) return int.parse(match.group(1)!);
    } catch (_) {}
    return 0;
  }

  List<QuestionEntity> _sortQuestions(List<QuestionEntity> rawQuestions) {
    rawQuestions.sort((a, b) {
      int numA = _extractQuestionNumber(a.questionText);
      int numB = _extractQuestionNumber(b.questionText);
      return numA.compareTo(numB);
    });
    return rawQuestions;
  }

  List<QuestionGroup> _groupQuestions(List<QuestionEntity> sortedQuestions) {
    List<QuestionGroup> groups = [];
    if (sortedQuestions.isEmpty) return groups;

    QuestionGroup currentGroup = QuestionGroup(
      passage: sortedQuestions[0].passage,
      questions: [sortedQuestions[0]],
    );

    for (int i = 1; i < sortedQuestions.length; i++) {
      final q = sortedQuestions[i];
      // Logic gom nhóm: Cùng passage -> Cùng nhóm (Trừ Part 5 passage null thì tách riêng)
      bool samePassage = (q.passage == currentGroup.passage);
      if (q.passage == null && currentGroup.passage == null) samePassage = false;

      if (samePassage) {
        currentGroup.questions.add(q);
      } else {
        groups.add(currentGroup);
        currentGroup = QuestionGroup(passage: q.passage, questions: [q]);
      }
    }
    groups.add(currentGroup);
    return groups;
  }

  // --- HÀM NHẢY ĐẾN CÂU HỎI ---
  void _jumpToQuestion(int questionIndex, List<QuestionGroup> groups) {
    // Tìm xem câu hỏi nằm ở Group nào (Page nào)
    int targetGroupIndex = -1;

    // Câu hỏi mục tiêu (đã sort)
    // Lưu ý: questionIndex ở đây là index trong list phẳng (sortedList)
    // Ta cần tìm xem item tại index này nằm trong group nào

    int count = 0;
    for (int i = 0; i < groups.length; i++) {
      int groupSize = groups[i].questions.length;
      // Nếu index nằm trong khoảng của group này
      if (questionIndex >= count && questionIndex < count + groupSize) {
        targetGroupIndex = i;
        break;
      }
      count += groupSize;
    }

    if (targetGroupIndex != -1) {
      _pageController.jumpToPage(targetGroupIndex);
      Navigator.pop(context); // Đóng Drawer sau khi chọn
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TestWorkBloc()..add(StartTestEvent(widget.testId, widget.minutes, filterPart: widget.filterPart)),
      child: BlocConsumer<TestWorkBloc, TestWorkState>(
        listener: (context, state) {
          if (state is TestSubmitted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => ResultScreen(state: state)),
            );
          }
        },
        builder: (context, state) {
          if (state is TestLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

          if (state is TestInProgress) {
            // Sắp xếp và gom nhóm dữ liệu
            final sortedList = _sortQuestions(state.questions);
            final groups = _groupQuestions(sortedList);
            final totalGroups = groups.length;

            return Scaffold(
              key: _scaffoldKey, // Gán key để mở Drawer
              backgroundColor: Colors.grey[100],

              // --- APP BAR ---
              appBar: AppBar(
                backgroundColor: Colors.blue[900],
                foregroundColor: Colors.white,
                centerTitle: true,
                // Nút Menu bên trái để mở danh sách câu hỏi
                leading: IconButton(
                  icon: const Icon(Icons.grid_view_rounded),
                  tooltip: "Danh sách câu hỏi",
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
                title: Column(
                  children: [
                    Text(widget.testTitle, style: const TextStyle(fontSize: 14)),
                    Text(
                      _formatTime(state.remainingSeconds),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: TextButton.icon(
                      onPressed: () => _showSubmitDialog(context),
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      label: const Text("NỘP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: TextButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                ],
              ),

              // --- DRAWER (MENU CÂU HỎI) ---
              drawer: Drawer(
                width: MediaQuery.of(context).size.width * 0.85,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
                      color: Colors.blue[900],
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Danh sách câu hỏi", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 5),
                          Text("Đã làm: ${sortedList.where((q) => q.selectedIndex != null).length} / ${sortedList.length}", style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5, // 5 câu 1 hàng
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: sortedList.length,
                        itemBuilder: (ctx, index) {
                          final question = sortedList[index];
                          final bool isAnswered = question.selectedIndex != null;
                          final int qNum = _extractQuestionNumber(question.questionText);

                          return InkWell(
                            onTap: () => _jumpToQuestion(index, groups),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAnswered ? Colors.blue[800] : Colors.grey[200],
                                border: isAnswered ? null : Border.all(color: Colors.grey.shade400),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                qNum > 0 ? "$qNum" : "${index + 1}",
                                style: TextStyle(
                                  color: isAnswered ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendItem(Colors.grey[200]!, "Chưa làm", Colors.black87),
                          _buildLegendItem(Colors.blue[800]!, "Đã làm", Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- BODY (PAGEVIEW) ---
              body: Column(
                children: [
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) => setState(() => _currentGroupIndex = index),
                      itemCount: totalGroups,
                      itemBuilder: (context, index) => _buildGroupPage(context, groups[index], index, totalGroups),
                    ),
                  ),
                  _buildBottomNavigation(context, totalGroups),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  // Widget chú thích màu sắc trong Drawer
  Widget _buildLegendItem(Color color, String text, Color textColor) {
    return Row(
      children: [
        Container(
          width: 24, height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade400)),
        ),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }

  // --- CÁC WIDGET CON (GIỮ NGUYÊN NHƯ CŨ) ---
  Widget _buildGroupPage(BuildContext context, QuestionGroup group, int groupIndex, int totalGroups) {
    bool hasPassage = group.passage != null && group.passage!.isNotEmpty;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPassage) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade100)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Reading Passage", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const Divider(),
                  Text(group.passage!, style: const TextStyle(fontSize: 16, height: 1.5)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: group.questions.length,
            itemBuilder: (ctx, qIdx) => _buildSingleQuestionItem(context, group.questions[qIdx]),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildSingleQuestionItem(BuildContext context, QuestionEntity question) {
    return Container(
      key: ValueKey("${question.id}_${question.selectedIndex}"),
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question.questionText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ...List.generate(question.options.length, (optIndex) {
            final isSelected = question.selectedIndex == optIndex;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue[50] : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade300),
              ),
              child: RadioListTile<int>(
                title: Text(question.options[optIndex], style: const TextStyle(fontSize: 14)),
                value: optIndex,
                groupValue: question.selectedIndex,
                activeColor: Colors.blue[800],
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                dense: true,
                onChanged: (value) {
                  context.read<TestWorkBloc>().add(SelectAnswerEvent(question.id, value!));
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, int totalGroups) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentGroupIndex > 0 ? () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.ease) : null,
            child: const Text("Trước"),
          ),
          Text("${_currentGroupIndex + 1} / $totalGroups", style: const TextStyle(fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: _currentGroupIndex < totalGroups - 1 ? () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease) : () => _showSubmitDialog(context),
            child: Text(_currentGroupIndex < totalGroups - 1 ? "Sau" : "Nộp bài"),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nộp bài?"),
        content: const Text("Bạn có muốn kết thúc bài thi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Làm tiếp")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<TestWorkBloc>().add(SubmitTestEvent(widget.testId, widget.testTitle));
            },
            child: const Text("Nộp ngay", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Class hỗ trợ
class QuestionGroup {
  final String? passage;
  final List<QuestionEntity> questions;
  QuestionGroup({this.passage, required this.questions});
}