class Word {
  final int? id;
  final String text;
  final String imageUrl;
  final String audioUrl;
  final int difficulty; // 1: Letters, 2: Syllables, 3: Words, 4: Sentences
  final String category;

  Word({
    this.id,
    required this.text,
    this.imageUrl = '',
    this.audioUrl = '',
    this.difficulty = 1,
    this.category = 'general',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'difficulty': difficulty,
      'category': category,
    };
  }

  factory Word.fromMap(Map<String, dynamic> map) {
    return Word(
      id: map['id'],
      text: map['text'],
      imageUrl: map['imageUrl'],
      audioUrl: map['audioUrl'],
      difficulty: map['difficulty'],
      category: map['category'],
    );
  }
}
