import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme/app_theme.dart';
import '../services/audio_service.dart';

class WordMatchGame extends StatefulWidget {
  const WordMatchGame({super.key});

  @override
  State<WordMatchGame> createState() => _WordMatchGameState();
}

class _WordMatchGameState extends State<WordMatchGame> {
  final List<Map<String, String>> items = [
    {'word': 'GATO', 'image': 'https://cdn-icons-png.flaticon.com/512/616/616408.png'},
    {'word': 'PERRO', 'image': 'https://cdn-icons-png.flaticon.com/512/616/616404.png'},
    {'word': 'CASA', 'image': 'https://cdn-icons-png.flaticon.com/512/619/619153.png'},
    {'word': 'SOL', 'image': 'https://cdn-icons-png.flaticon.com/512/481/481433.png'},
  ];

  Map<String, bool> score = {};
  late List<Map<String, String>> shuffledWords;
  late List<Map<String, String>> shuffledImages;

  @override
  void initState() {
    super.initState();
    _resetGame();
  }

  void _resetGame() {
    setState(() {
      score = {};
      shuffledWords = List.from(items)..shuffle();
      shuffledImages = List.from(items)..shuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Une la Palabra', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(10),
          child: LinearProgressIndicator(
            value: score.length / items.length,
            backgroundColor: AppTheme.lightGray,
            color: AppTheme.primaryColor,
            minHeight: 10,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '¿Cuál es cuál?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textColor),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Words column
                Column(
                  children: shuffledWords.map((item) {
                    return Draggable<String>(
                      data: item['word'],
                      feedback: _buildWordCard(item['word']!, true),
                      childWhenDragging: Opacity(opacity: 0.3, child: _buildWordCard(item['word']!, false)),
                      child: score[item['word']] == true
                          ? const SizedBox(height: 80, width: 120) // Placeholder when matched
                          : _buildWordCard(item['word']!, false),
                    );
                  }).toList(),
                ),
                // Images column
                Column(
                  children: shuffledImages.map((item) {
                    return DragTarget<String>(
                      onAcceptWithDetails: (details) {
                        final receivedWord = details.data;
                        if (receivedWord == item['word']) {
                          setState(() {
                            score[receivedWord] = true;
                          });
                          AudioService().playSuccess();
                          if (score.length == items.length) {
                            _showSuccessDialog();
                          }
                        }
                      },
                      builder: (context, candidateData, rejectedData) {
                        return _buildImageCard(item['image']!, score[item['word']!] == true);
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordCard(String word, bool isFeedback) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        width: 120,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor, width: 2),
          boxShadow: [
            if (!isFeedback)
              const BoxShadow(color: Color(0xFF58A700), offset: Offset(0, 4)),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          word,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
        ),
      ),
    );
  }

  Widget _buildImageCard(String imageUrl, bool isMatched) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: isMatched ? AppTheme.primaryColor.withValues(alpha: 0.2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMatched ? AppTheme.primaryColor : AppTheme.lightGray,
            width: 2,
          ),
        ),
        child: isMatched
            ? const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 50)
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Image.network(imageUrl),
              ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FadeInUp(
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(
            child: Text('¡Excelente!', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: AppTheme.warningColor, size: 80),
              const SizedBox(height: 20),
              const Text('Has aprendido nuevas palabras hoy.', textAlign: TextAlign.center),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _resetGame();
              },
              child: const Text('REPETIR'),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('FINALIZAR', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
    );
  }
}
