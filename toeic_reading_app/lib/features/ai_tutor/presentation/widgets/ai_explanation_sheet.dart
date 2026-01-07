import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../bloc/ai_bloc.dart';
import '../bloc/ai_state.dart';

class AiExplanationSheet extends StatelessWidget {
  const AiExplanationSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.blue, size: 30),
              const SizedBox(width: 10),
              const Text("Gia sư AI phân tích", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),

          // Nội dung chính
          Expanded(
            child: BlocBuilder<AiBloc, AiState>(
              builder: (context, state) {
                if (state is AiLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text("Đang phân tích... đợi xíu nha 🧠"),
                      ],
                    ),
                  );
                } else if (state is AiLoaded) {
                  return Markdown(
                    data: state.explanation,
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(color: Colors.blue, fontSize: 18),
                      p: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  );
                } else if (state is AiError) {
                  return Center(child: Text("Lỗi: ${state.message}", style: const TextStyle(color: Colors.red)));
                }
                return const Center(child: Text("Chọn một câu hỏi để AI giải thích."));
              },
            ),
          ),
        ],
      ),
    );
  }
}