import 'package:flutter/material.dart';

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dữ liệu giả lập các bài báo
    final List<Map<String, String>> articles = [
      {'title': 'Technology Trends 2025', 'desc': 'AI and Machine Learning...'},
      {'title': 'Healthy Habits', 'desc': 'How to improve your sleep...'},
      {'title': 'Global Economy', 'desc': 'Market analysis for the next quarter...'},
      {'title': 'Learning Flutter', 'desc': 'Best practices for Clean Architecture...'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Luyện Từ Vựng - Bài Báo'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: articles.length,
        separatorBuilder: (ctx, index) => const Divider(),
        itemBuilder: (context, index) {
          final article = articles[index];
          return Card(
            elevation: 2,
            child: ListTile(
              leading: const Icon(Icons.article, color: Colors.teal, size: 40),
              title: Text(article['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(article['desc']!),
              onTap: () {
                // Sau này sẽ chuyển sang màn hình đọc chi tiết
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đang mở bài: ${article['title']}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}