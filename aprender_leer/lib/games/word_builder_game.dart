import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme/app_theme.dart';
import '../services/audio_service.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';

class WordScrambleGame extends StatefulWidget {
  const WordScrambleGame({super.key});

  @override
  State<WordScrambleGame> createState() => _WordScrambleGameState();
}

class _WordScrambleGameState extends State<WordScrambleGame> {
  final Map<String, String> wordData = {'word': 'SOL', 'hint': 'Brilla en el cielo'};
  late List<String> scrambledLetters;
  List<String> currentGuess = [];

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      scrambledLetters = wordData['word']!.split('')..shuffle();
      currentGuess = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ordena las Letras', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                wordData['hint']!,
                style: const TextStyle(fontSize: 22, color: Colors.grey),
              ),
              const SizedBox(height: 60),
              // Guess area
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(wordData['word']!.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    width: 50,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppTheme.primaryColor, width: 3)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      currentGuess.length > index ? currentGuess[index] : '',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 80),
              // Letters picks
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: scrambledLetters.asMap().entries.map((entry) {
                  return ZoomIn(
                    delay: Duration(milliseconds: entry.key * 100),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          currentGuess.add(entry.value);
                          scrambledLetters.removeAt(entry.key);
                        });
                        if (currentGuess.length == wordData['word']!.length) {
                          _checkResult();
                        }
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.secondaryColor, width: 2),
                          boxShadow: const [BoxShadow(color: Color(0xFF1CB0F6), offset: Offset(0, 4))],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.secondaryColor),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              TextButton(
                onPressed: _resetGame,
                child: const Text('EMPEZAR DE NUEVO', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _checkResult() {
    String guess = currentGuess.join('');
    if (guess == wordData['word']) {
      AudioService().playSuccess();
      _saveScore(30); // E.g., 30 points for a correct word
      _showSuccessDialog();
    } else {
      AudioService().playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Inténtalo de nuevo!'), backgroundColor: AppTheme.accentColor),
      );
      _resetGame();
    }
  }

  Future<void> _saveScore(int score) async {
    try {
      final progress = ProgressService();
      final ninoId = await progress.getNinoId();
      if (ninoId != null) {
        await ApiService().saveScore(
          ninoId: ninoId,
          category: 'palabras',
          gameType: 'word_builder',
          score: score,
          stars: 3, // Assuming perfect for now
        );
      }
    } catch (e) {
      debugPrint('Error saving score: $e');
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Center(child: Text('¡MUY BIEN!')),
        content: const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 80),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('CONTINUAR'),
          ),
        ],
      ),
    );
  }
}
