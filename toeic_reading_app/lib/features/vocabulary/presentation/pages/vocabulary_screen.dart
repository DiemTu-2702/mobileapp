import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'flashcard_screen.dart';

class VocabularyScreen extends StatelessWidget {
  const VocabularyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bộ Từ Vựng TOEIC'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('topics').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có chủ đề nào.\nHãy chạy hàm nạp dữ liệu (Seed Data)!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final topics = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
            itemCount: topics.length,
            itemBuilder: (context, index) {
              final topicDoc = topics[index];
              final data = topicDoc.data() as Map<String, dynamic>;

              return _buildTopicCard(context, topicDoc.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _buildTopicCard(BuildContext context, String docId, Map<String, dynamic> data) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  FlashcardScreen(
                    topicId: docId,
                    topicName: data['name'] ?? 'Chủ đề',
                    topicDescription: data['description'] ??
                        '',
                  ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  data['icon'] ?? '📚',
                  style: const TextStyle(fontSize: 28),
                ),
              ),

              const SizedBox(height: 15),

              // 2. Tên chủ đề (Tiếng Anh) - In đậm
              Text(
                data['name'] ?? 'No Name',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1565C0),
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 4),

              Text(
                data['description'] ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w400,
                ),
              ),

              const Spacer(),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${data['totalWords'] ?? 0} từ vựng',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  }