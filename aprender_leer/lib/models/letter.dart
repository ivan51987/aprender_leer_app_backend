class Letter {
  final String char;
  final String audioPath;
  final String imagePath;
  final bool isVowel;

  Letter({
    required this.char,
    required this.audioPath,
    this.imagePath = '',
    this.isVowel = false,
  });
}
