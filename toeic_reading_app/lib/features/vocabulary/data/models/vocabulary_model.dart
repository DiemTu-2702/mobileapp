import 'package:cloud_firestore/cloud_firestore.dart';

class VocabularyModel {
  final String id;
  final String englishWord;
  final String vietnameseDefinition;
  final String? pronunciation;
  final String? partOfSpeech;
  final String? example;
  bool isMastered;

  VocabularyModel({
    required this.id,
    required this.englishWord,
    required this.vietnameseDefinition,
    this.pronunciation,
    this.partOfSpeech,
    this.example,
    this.isMastered = false,
  });

  // Chuyển từ Firestore JSON sang Object Dart
  factory VocabularyModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VocabularyModel(
      id: doc.id,
      englishWord: data['englishWord'] ?? '',
      vietnameseDefinition: data['vietnameseDefinition'] ?? '',
      // 👇 Map thêm 2 trường mới này vào
      pronunciation: data['pronunciation'],
      partOfSpeech: data['partOfSpeech'],
      example: data['example'],
      isMastered: data['isMastered'] ?? false,
    );
  }

  // Chuyển từ Object Dart sang JSON (để lưu lên Firestore)
  Map<String, dynamic> toMap() {
    return {
      'englishWord': englishWord,
      'vietnameseDefinition': vietnameseDefinition,
      'pronunciation': pronunciation,
      'partOfSpeech': partOfSpeech,
      'example': example,
      'isMastered': isMastered,
    };
  }
}