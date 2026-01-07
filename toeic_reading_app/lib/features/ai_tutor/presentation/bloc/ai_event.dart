abstract class AiEvent {}

class AskAiEvent extends AiEvent {
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final List<dynamic> options;

  AskAiEvent({
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.options,
  });
}

class AnalyzeFullTestEvent extends AiEvent {
  final int score;
  final int totalQuestions;
  final List<Map<String, dynamic>> fullQuestions;
  final Map<String, int?> userAnswers;

  AnalyzeFullTestEvent({
    required this.score,
    required this.totalQuestions,
    required this.fullQuestions,
    required this.userAnswers,
  });
}