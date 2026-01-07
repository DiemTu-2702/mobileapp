import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// --- 1. THÊM CÁC IMPORT CẦN THIẾT ---
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart'; // Đường dẫn tới AuthBloc
import '../../../auth/presentation/pages/auth_screen.dart'; // Đường dẫn tới AuthScreen

import 'test_detail_screen.dart';

class TestListScreen extends StatelessWidget {
  const TestListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Luyện Đề TOEIC'),
          centerTitle: true,
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: false,
            indicatorColor: Colors.amber,
            indicatorWeight: 4,
            labelColor: Colors.white,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(text: "Part 5"),
              Tab(text: "Part 6"),
              Tab(text: "Part 7"),
              Tab(text: "Full Test"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TestListByFilter(keyword: "Part 5", partNum: 5),
            _TestListByFilter(keyword: "Part 6", partNum: 6),
            _TestListByFilter(keyword: "Part 7", partNum: 7),
            _TestListByFilter(keyword: "Full", partNum: null),
          ],
        ),
      ),
    );
  }
}

class _TestListByFilter extends StatelessWidget {
  final String keyword;
  final int? partNum;

  const _TestListByFilter({required this.keyword, this.partNum});

  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Yêu cầu đăng nhập",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text("Bạn cần đăng nhập tài khoản để thực hiện bài thi này và lưu kết quả."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800], foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            },
            child: const Text("Đăng nhập ngay"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tests')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text("Đang tải dữ liệu..."));
        }

        final docs = snapshot.data!.docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final title = (data['title'] ?? "").toString();
          return title.contains(keyword);
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_off, size: 50, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text("Chưa có đề thi $keyword", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;

            Color iconColor = Colors.blue;
            if (partNum == 5) iconColor = Colors.orange;
            else if (partNum == 6) iconColor = Colors.green;
            else if (partNum == 7) iconColor = Colors.purple;
            else iconColor = Colors.red;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),

                onTap: () {
                  final authState = context.read<AuthBloc>().state;

                  if (authState is Authenticated) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TestDetailScreen(
                          testId: doc.id,
                          filterPart: partNum,
                        ),
                      ),
                    );
                  } else {
                    _showLoginDialog(context);
                  }
                },
                // ----------------------------------

                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                              partNum?.toString() ?? "F",
                              style: TextStyle(color: iconColor, fontWeight: FontWeight.bold, fontSize: 20)
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? "No Title",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text("${data['timeLimitMinutes']} phút", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                const SizedBox(width: 15),
                                const Icon(Icons.list_alt, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text("${data['totalQuestions']} câu", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}