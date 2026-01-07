abstract class AiState {}

class AiInitial extends AiState {}

class AiLoading extends AiState {}

class AiLoaded extends AiState {
  final String explanation; // Chứa nội dung trả lời của AI
  AiLoaded(this.explanation);
}

class AiError extends AiState {
  final String message;
  AiError(this.message);
}