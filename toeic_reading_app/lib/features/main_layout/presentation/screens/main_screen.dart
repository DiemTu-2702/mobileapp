import 'package:flutter/material.dart';
import '../../../test_reading/presentation/pages/test_list_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ứng dụng TOEIC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: Triển khai logic Logout
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: const TestListScreen(),
    );
  }
}