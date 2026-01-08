class QuizOption {
  final int id;
  final String text;
  final bool isCorrect; // Only used in results if needed

  QuizOption({
    required this.id,
    required this.text,
    this.isCorrect = false,
  });

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: json['id'],
      text: json['text'],
      isCorrect: json['is_correct'] ?? false,
    );
  }
}

class QuizQuestion {
  final int id;
  final String prompt;
  final List<QuizOption> options;

  QuizQuestion({
    required this.id,
    required this.prompt,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List<dynamic>? ?? [])
        .map((o) => QuizOption.fromJson(o as Map<String, dynamic>))
        .toList();
    return QuizQuestion(
      id: json['id'],
      prompt: json['prompt'],
      options: opts,
    );
  }
}

class QuizData {
  final int moduleId;
  final String moduleTitle;
  final List<QuizQuestion> questions;

  QuizData({
    required this.moduleId,
    required this.moduleTitle,
    required this.questions,
  });

  factory QuizData.fromJson(Map<String, dynamic> json) {
    return QuizData(
      moduleId: json['module_id'],
      moduleTitle: json['module_title'],
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizResult {
  final int moduleId;
  final int correctAnswers;
  final int totalQuestions;
  final int score;
  final bool passed;

  QuizResult({
    required this.moduleId,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.score,
    required this.passed,
  });

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    return QuizResult(
      moduleId: json['module_id'],
      correctAnswers: json['correct_answers'],
      totalQuestions: json['total_questions'],
      score: json['score'],
      passed: json['passed'],
    );
  }
}
