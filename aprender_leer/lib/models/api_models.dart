// Models for API responses from the letras_voz backend.

class CategoryItem {
  final String id;
  final String text;
  final String audioUrl;

  const CategoryItem({
    required this.id,
    required this.text,
    required this.audioUrl,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
    );
  }
}

class Category {
  final String id;
  final String label;
  final List<CategoryItem> items;

  const Category({
    required this.id,
    required this.label,
    required this.items,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return Category(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? '',
      items: rawItems
          .map((e) => CategoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class QuizQuestion {
  final String prompt;
  final String audioUrl;
  final List<String> options;
  final String correctAnswer;

  const QuizQuestion({
    required this.prompt,
    required this.audioUrl,
    required this.options,
    required this.correctAnswer,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return QuizQuestion(
      prompt: json['prompt'] as String? ?? '',
      audioUrl: json['audioUrl'] as String? ?? '',
      options: rawOptions.map((e) => e as String).toList(),
      correctAnswer: json['correctAnswer'] as String? ?? '',
    );
  }
}
