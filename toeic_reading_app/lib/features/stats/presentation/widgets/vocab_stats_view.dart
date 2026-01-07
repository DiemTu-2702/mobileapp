import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VocabStatsView extends StatelessWidget {
  const VocabStatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('topics').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Center(child: Text("Lỗi kết nối Firebase"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _calculateVocabDetails(snapshot.data!.docs),
          builder: (context, futureSnap) {
            if (!futureSnap.hasData) return const Center(child: CircularProgressIndicator());

            final data = futureSnap.data!;
            int totalWords = 0;
            int masteredWords = 0;

            for (var item in data) {
              totalWords += (item['total'] as int);
              masteredWords += (item['mastered'] as int);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPieChartSection(masteredWords, totalWords),
                  const SizedBox(height: 30),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Tiến độ theo chủ đề",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...data.map((topic) => _buildTopicProgressBar(topic)).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- HELPER METHODS ---
  Future<List<Map<String, dynamic>>> _calculateVocabDetails(List<QueryDocumentSnapshot> topics) async {
    List<Map<String, dynamic>> results = [];
    for (var doc in topics) {
      var wordsSnapshot = await doc.reference.collection('words').get();
      int total = wordsSnapshot.docs.length;
      int mastered = wordsSnapshot.docs.where((w) => w.data().containsKey('isMastered') && w.data()['isMastered'] == true).length;
      results.add({'name': doc['name'], 'total': total, 'mastered': mastered});
    }
    return results;
  }

  Widget _buildPieChartSection(int mastered, int total) {
    if (total == 0) return const Text("Chưa có dữ liệu.");
    int notMastered = total - mastered;
    return SizedBox(
      height: 250,
      child: PieChart(PieChartData(
        sections: [
          PieChartSectionData(
            color: Colors.green,
            value: mastered.toDouble(),
            title: '${((mastered / (total == 0 ? 1 : total)) * 100).toStringAsFixed(0)}%',
            radius: 70,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          PieChartSectionData(
            color: Colors.red.shade200,
            value: notMastered.toDouble(),
            title: '',
            radius: 60,
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 50,
      )),
    );
  }

  Widget _buildTopicProgressBar(Map<String, dynamic> topic) {
    double percent = topic['total'] == 0 ? 0 : topic['mastered'] / topic['total'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(topic['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
            Text("${topic['mastered']}/${topic['total']}", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey[200],
              color: percent == 1 ? Colors.green : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}