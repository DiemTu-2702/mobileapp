import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../bloc/ai_bloc.dart';
import '../bloc/ai_state.dart';

class FullTestAnalysisCard extends StatefulWidget {
  final VoidCallback onAnalyzePressed;

  const FullTestAnalysisCard({super.key, required this.onAnalyzePressed});

  @override
  State<FullTestAnalysisCard> createState() => _FullTestAnalysisCardState();
}

class _FullTestAnalysisCardState extends State<FullTestAnalysisCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AiBloc, AiState>(
      builder: (context, state) {
        if (state is AiLoading) {
          return _buildContainer(
            child: const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text("AI đang đọc bài làm của bạn...", style: TextStyle(fontStyle: FontStyle.italic)),
              ],
            ),
          );
        }

        if (state is AiLoaded && _isExpanded) {
          return _buildContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isResult: true),
                const Divider(),
                MarkdownBody(
                  data: state.explanation,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                    h2: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                    p: const TextStyle(fontSize: 14, height: 1.5),
                    strong: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _isExpanded = false),
                    child: const Text("Thu gọn"),
                  ),
                )
              ],
            ),
          );
        }

        return _buildContainer(
          child: Column(
            children: [
              _buildHeader(isResult: false),
              // 👇 SỬA Ở ĐÂY: Dùng AiLoaded
              if (state is AiLoaded) ...[
                const SizedBox(height: 5),
                const Text("✅ Đã có kết quả phân tích", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ]
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader({required bool isResult}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 👇 Bọc phần nội dung bên trái vào Expanded
        Expanded(
          child: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber, size: 28),
              const SizedBox(width: 10),
              // 👇 Bọc Column chứa chữ vào Expanded để tránh tràn chữ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "AI Trợ Lý Tổng Hợp",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      "Phân tích lỗi sai & Gợi ý ôn tập",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        ElevatedButton(
          onPressed: () {
            if (!isResult) {
              setState(() => _isExpanded = true);
              widget.onAnalyzePressed();
            } else {
              widget.onAnalyzePressed();
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[50],
            foregroundColor: Colors.blue[800],
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            minimumSize: const Size(80, 36),
          ),
          child: Text(
            isResult ? "Phân tích lại" : "Phân tích ngay",
            style: const TextStyle(fontSize: 12),
          ),
        )
      ],
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }
}