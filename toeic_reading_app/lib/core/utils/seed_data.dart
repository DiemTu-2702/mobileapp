import 'package:cloud_firestore/cloud_firestore.dart';

final List<Map<String, dynamic>> _topicData7to15 = [

];

Future<void> seedToeicVocabulary() async {
  final firestore = FirebaseFirestore.instance;
  final batch = firestore.batch();

  print("🚀 Bắt đầu nạp Topic 7 đến 15...");

  for (var topic in _topicData7to15) {
    final topicRef = firestore.collection('topics').doc(topic['id']);
    batch.set(topicRef, {
      'name': topic['name'],
      'description': topic['description'],
      'icon': topic['icon'],
      'totalWords': (topic['words'] as List).length,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final wordsList = topic['words'] as List<Map<String, String>>;
    for (var vocab in wordsList) {
      final wordRef = topicRef.collection('words').doc();
      batch.set(wordRef, {
        'englishWord': vocab['en'],
        'vietnameseDefinition': vocab['vn'],
        'partOfSpeech': vocab['type'],
        'pronunciation': vocab['ipa'],
        'isMastered': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  await batch.commit();
  print("✅ Đã nạp thành công Topic 7-15!");
}