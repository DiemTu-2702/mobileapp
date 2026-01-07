import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Import thư viện biểu đồ

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/pages/auth_screen.dart';

import 'settings_screen.dart';
import 'stats_screen.dart';
import 'history_detail_screen.dart';
import '../../../admin/presentation/pages/admin_dashboard_screen.dart';
import '../../../test_reading/data/models/test_history_model.dart';

// --- DATA PLACEHOLDER ---
const List<Map<String, dynamic>> part5Data = [];
const List<Map<String, dynamic>> part6Data = [];
const List<Map<String, dynamic>> part7Data = [];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Biến quản lý trạng thái Toggle Button: 0 = Lịch sử làm bài, 1 = Thành tựu
  int _selectedTab = 0;

  Future<void> _refreshUser() async {
    await FirebaseAuth.instance.currentUser?.reload();
    if (mounted) {
      context.read<AuthBloc>().add(CheckAuthStatusEvent());
      setState(() {});
    }
  }

  void _confirmDelete(BuildContext context, String userId, String historyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text("Xóa lịch sử?", style: TextStyle(color: Colors.red)),
        content: const Text("Bạn có chắc chắn muốn xóa kết quả bài thi này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await FirebaseFirestore.instance.collection('users').doc(userId).collection('history').doc(historyId).delete();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã xóa thành công.")));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
              }
            },
            child: const Text("Xóa"),
          ),
        ],
      ),
    );
  }

  Future<void> _seedTestFromData(BuildContext context, {required String testTitle, required int timeLimit, required List<Map<String, dynamic>> questionsData}) async {
    if (questionsData.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chưa có dữ liệu mẫu!'))); return; }
    final firestore = FirebaseFirestore.instance;
    try {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Đang tạo đề: $testTitle...')));
      final testRef = firestore.collection('tests').doc();
      await testRef.set({ 'title': testTitle, 'description': 'ETS 2024', 'timeLimitMinutes': timeLimit, 'totalQuestions': questionsData.length, 'createdAt': FieldValue.serverTimestamp() });
      WriteBatch batch = firestore.batch();
      int count = 0;
      final questionsRef = testRef.collection('questions');
      for (var qData in questionsData) {
        final docRef = questionsRef.doc();
        String text = qData['questionText'] ?? "";
        int qNum = 0;
        final regex = RegExp(r'^(\d+)');
        final match = regex.firstMatch(text.trim());
        if (match != null) qNum = int.parse(match.group(1)!);
        int part = 5;
        if (qNum >= 101 && qNum <= 130) part = 5; else if (qNum >= 131 && qNum <= 146) part = 6; else if (qNum >= 147) part = 7;
        Map<String, dynamic> dataToSave = Map.from(qData);
        dataToSave['part'] = part;
        batch.set(docRef, dataToSave);
        count++;
        if (count >= 400) { await batch.commit(); batch = firestore.batch(); count = 0; }
      }
      if (count > 0) await batch.commit();
      if (mounted) { ScaffoldMessenger.of(context).hideCurrentSnackBar(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Đã nạp xong!'))); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'))); }
  }

  ImageProvider? _getAvatarImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return null;
    try {
      return MemoryImage(base64Decode(photoUrl));
    } catch (e) {
      return null;
    }
  }

  // --- HÀM VẼ BIỂU ĐỒ TRÒN ---
  Widget _buildDistributionChart(int p5, int p6, int p7, int full, int total) {
    if (total == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: Colors.blueGrey, size: 20),
              const SizedBox(width: 8),
              const Text("Phân bổ luyện tập", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // BIỂU ĐỒ TRÒN
              SizedBox(
                height: 130, // Tăng chiều cao khung chứa
                width: 130,  // Tăng chiều rộng khung chứa
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 30, // Giảm bán kính tâm (cũ là 40)
                    sections: [
                      if (p5 > 0) _pieSection(p5, total, Colors.blue),
                      if (p6 > 0) _pieSection(p6, total, Colors.orange),
                      if (p7 > 0) _pieSection(p7, total, Colors.purple),
                      if (full > 0) _pieSection(full, total, Colors.green),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 25),
              // CHÚ THÍCH
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (p5 > 0) _legendItem(Colors.blue, "Part 5: $p5 bài"),
                    if (p6 > 0) _legendItem(Colors.orange, "Part 6: $p6 bài"),
                    if (p7 > 0) _legendItem(Colors.purple, "Part 7: $p7 bài"),
                    if (full > 0) _legendItem(Colors.green, "Full Test: $full bài"),
                    const Divider(height: 15),
                    Text("Tổng cộng: $total bài", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  // Đã giảm radius xuống còn 35 (Tổng bán kính = 30 + 35 = 65 -> Đường kính 130, vừa khít khung)
  PieChartSectionData _pieSection(int value, int total, Color color) {
    return PieChartSectionData(
      color: color,
      value: value.toDouble(),
      title: '${((value / total) * 100).toStringAsFixed(0)}%',
      radius: 35, // Giảm độ dày vòng tròn (cũ là 50)
      titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _legendItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ],
      ),
    );
  }

  // --- WIDGET TOGGLE BUTTON ---
  Widget _buildToggleButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildToggleItem("Lịch sử làm bài", 0),
          _buildToggleItem("Thành tựu", 1),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, int index) {
    final bool isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Hồ sơ cá nhân'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
              if (result == true) { await _refreshUser(); }
            },
          )
        ],
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is Unauthenticated || state is AuthError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text("Bạn chưa đăng nhập", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
                    },
                    child: const Text("Đăng nhập ngay"),
                  ),
                ],
              ),
            );
          }

          if (state is Authenticated) {
            final user = FirebaseAuth.instance.currentUser;

            if (user == null) {
              context.read<AuthBloc>().add(CheckAuthStatusEvent());
              return const Center(child: CircularProgressIndicator());
            }

            final role = state.user.role;

            return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                builder: (context, userSnapshot) {

                  String displayName = user.displayName ?? "";
                  String? photoUrl;

                  if (userSnapshot.hasData && userSnapshot.data!.exists) {
                    final data = userSnapshot.data!.data() as Map<String, dynamic>;
                    if (data['displayName'] != null) displayName = data['displayName'];
                    if (data['photoUrl'] != null) photoUrl = data['photoUrl'];
                  }

                  if (displayName.isEmpty) {
                    displayName = user.email?.split('@')[0] ?? "Người dùng";
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // --- HEADER INFO ---
                        Container(
                          width: double.infinity,
                          color: Theme.of(context).appBarTheme.backgroundColor,
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundColor: Colors.white,
                                backgroundImage: _getAvatarImage(photoUrl),
                                child: (photoUrl == null)
                                    ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : "U", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue[800]))
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                                    const SizedBox(height: 5),
                                    Text(user.email ?? "", style: const TextStyle(color: Colors.white70, fontSize: 14)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- BODY ---
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nút Admin
                              if (role == 'admin')
                                Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(color: isDark ? Colors.red.withOpacity(0.15) : Colors.red[50], borderRadius: BorderRadius.circular(12)),
                                  child: ListTile(
                                    leading: const Icon(Icons.admin_panel_settings, color: Colors.redAccent),
                                    title: const Text("Vào trang quản trị (Admin)", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                                    trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen())),
                                  ),
                                ),

                              Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(color: isDark ? Colors.blue.withOpacity(0.15) : Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  leading: const Icon(Icons.bar_chart, color: Colors.blue),
                                  title: const Text("Thống kê tiến độ học tập", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blue),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StatsScreen(userId: user.uid))),
                                ),
                              ),

                              if (role == 'admin')
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: cardColor, border: Border.all(color: Colors.orange.shade200), borderRadius: BorderRadius.circular(12)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("⚙️ Admin Zone: Nạp dữ liệu mẫu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 10, runSpacing: 10,
                                        children: [
                                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white), onPressed: () => _seedTestFromData(context, testTitle: "Test 1 - Part 5", timeLimit: 17, questionsData: part5Data), child: const Text("Part 5")),
                                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () => _seedTestFromData(context, testTitle: "Test 1 - Part 6", timeLimit: 8, questionsData: part6Data), child: const Text("Part 6")),
                                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white), onPressed: () => _seedTestFromData(context, testTitle: "Test 1 - Part 7", timeLimit: 55, questionsData: part7Data), child: const Text("Part 7")),
                                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => _seedTestFromData(context, testTitle: "ETS 2024 Full", timeLimit: 75, questionsData: [...part5Data, ...part6Data, ...part7Data]), child: const Text("Full Test")),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                              // TOGGLE BUTTON (Lịch sử làm bài | Thành tựu)
                              _buildToggleButton(),
                              const SizedBox(height: 10),

                              // NỘI DUNG THAY ĐỔI THEO TOGGLE
                              if (_selectedTab == 0)
                              // TAB 0: LỊCH SỬ (Biểu đồ + Danh sách)
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).collection('history').orderBy('timestamp', descending: true).snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: Center(child: CircularProgressIndicator()),
                                      );
                                    }

                                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                      return Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Bạn chưa làm bài thi nào", style: TextStyle(color: textColor.withOpacity(0.6)))));
                                    }

                                    final historyDocs = snapshot.data!.docs;

                                    // Logic tính toán biểu đồ
                                    int countP5 = 0, countP6 = 0, countP7 = 0, countFull = 0;
                                    for (var doc in historyDocs) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      final title = (data['testTitle'] ?? "").toString();
                                      if (title.contains('Part 5')) countP5++;
                                      else if (title.contains('Part 6')) countP6++;
                                      else if (title.contains('Part 7')) countP7++;
                                      else if (title.toLowerCase().contains('full')) countFull++;
                                    }
                                    int total = countP5 + countP6 + countP7 + countFull;

                                    return Column(
                                      children: [
                                        // Biểu đồ phân tích
                                        _buildDistributionChart(countP5, countP6, countP7, countFull, total),

                                        // Danh sách bài làm
                                        ListView.separated(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          itemCount: historyDocs.length,
                                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                                          itemBuilder: (context, index) {
                                            try {
                                              final historyItem = TestHistoryModel.fromSnapshot(historyDocs[index]);
                                              final scoreColor = historyItem.score >= 300 ? Colors.green : Colors.orange;

                                              return Card(
                                                color: cardColor,
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                child: ListTile(
                                                  leading: CircleAvatar(backgroundColor: scoreColor.withOpacity(0.15), child: Text("${historyItem.score}", style: TextStyle(color: scoreColor, fontWeight: FontWeight.bold, fontSize: 13))),
                                                  title: Text(historyItem.testTitle, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                                                  subtitle: Text(DateFormat('dd/MM/yyyy HH:mm').format(historyItem.date), style: TextStyle(color: textColor.withOpacity(0.6))),
                                                  trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => _confirmDelete(context, user.uid, historyDocs[index].id)),
                                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryDetailScreen(history: historyItem))),
                                                ),
                                              );
                                            } catch (e) {
                                              return const SizedBox.shrink();
                                            }
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                )
                              else
                              // TAB 1: THÀNH TỰU (Placeholder)
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.emoji_events_outlined, size: 60, color: Colors.amber[700]),
                                      const SizedBox(height: 10),
                                      const Text("Tính năng Thành tựu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 5),
                                      const Text("Sẽ sớm ra mắt!", style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
            );
          }

          // Fallback
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}