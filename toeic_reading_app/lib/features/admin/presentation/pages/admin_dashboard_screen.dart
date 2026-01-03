import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../test_reading/presentation/pages/test_detail_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          backgroundColor: Colors.blue[800],
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.people), text: 'Quản lý User'),
              Tab(icon: Icon(Icons.library_books), text: 'Quản lý Đề thi'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _UserManagementTab(),
            _TestManagementTab(),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 1: QUẢN LÝ USER (XEM - SỬA - XÓA)
// =============================================================================
class _UserManagementTab extends StatelessWidget {
  const _UserManagementTab();

  // 1. HÀM SỬA USER
  void _editUser(BuildContext context, DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final nameController = TextEditingController(text: data['name'] ?? '');

    // Biến lưu role hiện tại (mặc định là 'user' nếu null)
    String selectedRole = (data['role'] == 'admin') ? 'admin' : 'user';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        // Dùng StatefulBuilder để cập nhật UI trong Dialog (Dropdown)
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Chỉnh sửa thông tin"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Nhập Tên
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Tên hiển thị"),
                ),
                const SizedBox(height: 20),

                // Chọn Quyền (Dropdown)
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(labelText: "Phân quyền"),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text("User (Người dùng)")),
                    DropdownMenuItem(value: 'admin', child: Text("Admin (Quản trị)")),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedRole = value);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Hủy"),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Cập nhật Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(doc.id)
                      .update({
                    'name': nameController.text,
                    'role': selectedRole,
                  });

                  if (context.mounted) Navigator.pop(ctx);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật thành công!')),
                  );
                },
                child: const Text("Lưu thay đổi"),
              ),
            ],
          );
        },
      ),
    );
  }

  // 2. HÀM XÓA USER
  void _deleteUser(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa user này khỏi danh sách?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(docId).delete();
              Navigator.pop(ctx);
            },
            child: const Text("Xóa vĩnh viễn"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final users = snapshot.data!.docs;

        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(),
          itemBuilder: (context, index) {
            final doc = users[index];
            final data = doc.data() as Map<String, dynamic>;
            final docId = doc.id;
            final email = data['email'] ?? 'No Email';
            final role = data['role'] ?? 'user';

            return ListTile(
              // Avatar hiển thị theo Role
              leading: CircleAvatar(
                backgroundColor: role == 'admin' ? Colors.red[100] : Colors.blue[100],
                child: Icon(
                    role == 'admin' ? Icons.security : Icons.person,
                    color: role == 'admin' ? Colors.red : Colors.blue
                ),
              ),
              title: Text(
                data['name'] ?? 'Chưa đặt tên',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(email),
                  // Hiển thị Badge Role nhỏ
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: role == 'admin' ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(4)
                    ),
                    child: Text(
                      role.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  )
                ],
              ),
              isThreeLine: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // NÚT SỬA (MỚI)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _editUser(context, doc),
                  ),
                  // NÚT XÓA
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.grey),
                    onPressed: () => _deleteUser(context, docId),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// =============================================================================
// TAB 2: QUẢN LÝ ĐỀ THI (GIỮ NGUYÊN CODE CŨ)
// =============================================================================
class _TestManagementTab extends StatelessWidget {
  const _TestManagementTab();

  void _deleteTest(BuildContext context, String docId) {
    FirebaseFirestore.instance.collection('tests').doc(docId).delete();
  }

  void _showTestForm(BuildContext context, {DocumentSnapshot? doc}) {
    final titleController = TextEditingController(text: doc?['title']);
    final timeController = TextEditingController(text: doc?['timeLimitMinutes']?.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc == null ? "Thêm bài thi mới" : "Sửa bài thi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Tên bài thi")),
            TextField(controller: timeController, decoration: const InputDecoration(labelText: "Thời gian (phút)"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'title': titleController.text,
                'timeLimitMinutes': int.tryParse(timeController.text) ?? 60,
                'totalQuestions': 100,
                'description': 'Được cập nhật bởi Admin',
                'imageUrl': '',
              };

              if (doc == null) {
                await FirebaseFirestore.instance.collection('tests').add(data);
              } else {
                await FirebaseFirestore.instance.collection('tests').doc(doc.id).update(data);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTestForm(context),
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('tests').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final tests = snapshot.data!.docs;

          return ListView.builder(
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final data = tests[index].data() as Map<String, dynamic>;
              final docId = tests[index].id;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(data['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['timeLimitMinutes']} phút"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showTestForm(context, doc: tests[index]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteTest(context, docId),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TestDetailScreen(testId: docId)));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}