class QuestionEntity {
  final String id;
  final String questionText;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int? selectedIndex;
  final String? passage;
  final int part;

  QuestionEntity({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.selectedIndex,
    this.passage,
    required this.part,
  });

  QuestionEntity copyWith({
    String? id,
    String? questionText,
    List<String>? options,
    int? correctIndex,
    String? explanation,
    int? selectedIndex,
    String? passage,
    int? part,
  }) {
    return QuestionEntity(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctIndex: correctIndex ?? this.correctIndex,
      explanation: explanation ?? this.explanation,
      selectedIndex: selectedIndex ?? this.selectedIndex,
      passage: passage ?? this.passage,
      part: part ?? this.part,
    );
  }
}