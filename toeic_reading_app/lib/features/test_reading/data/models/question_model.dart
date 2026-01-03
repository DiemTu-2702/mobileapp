import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/question_entity.dart';

class QuestionModel extends QuestionEntity {
  QuestionModel({
    required super.id,
    required super.questionText,
    required super.options,
    required super.correctIndex,
    required super.explanation,
    super.selectedIndex,
    super.passage,
    required super.part,
  });

  factory QuestionModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return QuestionModel(
      id: doc.id,
      questionText: data['questionText'] ?? '',
      options: List<String>.from(data['options'] ?? []),
      correctIndex: data['correctIndex'] ?? 0,
      explanation: data['explanation'] ?? '',
      selectedIndex: data['selectedIndex'],
      passage: data['passage'],
      part: data['part'] ?? 5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionText': questionText,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'selectedIndex': selectedIndex,
      'passage': passage,
      'part': part,
    };
  }
}