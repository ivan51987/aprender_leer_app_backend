import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/word.dart';

class AIService {
  final String? apiKey;
  GenerativeModel? _model;

  AIService({this.apiKey}) {
    if (apiKey != null) {
      _model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey!);
    }
  }

  Future<List<String>> generateWords(String prompt, {int count = 10}) async {
    if (_model == null) {
      // Fallback or base structure message
      print("AI Service: No API Key provided. Returning mock data.");
      return List.generate(count, (index) => "Palabra ${index + 1}");
    }

    try {
      final response = await _model!.generateContent([
        Content.text("Genera una lista de $count palabras en español para niños que están aprendiendo a leer. Formato: solo las palabras separadas por comas. Contexto: $prompt")
      ]);
      
      return response.text?.split(',').map((e) => e.trim()).toList() ?? [];
    } catch (e) {
      print("Error generating words: $e");
      return [];
    }
  }

  // Base method to be expanded as needed
  Future<Word?> generateWordDetails(String word) async {
    // This could generate categories, difficulty, etc.
    return Word(text: word, difficulty: 1, category: 'AI Generated');
  }
}
