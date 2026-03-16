import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/audio_service.dart';

class MissingLetterGame extends StatefulWidget {
  const MissingLetterGame({super.key});

  @override
  State<MissingLetterGame> createState() => _MissingLetterGameState();
}

class _MissingLetterGameState extends State<MissingLetterGame> {
  final Map<String, dynamic> wordData = {'full': 'LUPA', 'missing': 'L_PA', 'letter': 'U', 'options': ['A', 'U', 'I']};
  String? selectedLetter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completa la Palabra', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, size: 100, color: AppTheme.secondaryColor),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: wordData['missing']!.split('').map((char) {
                if (char == '_') {
                  return Container(
                    width: 60,
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      selectedLetter ?? '?',
                      style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  );
                }
                return Text(
                  char,
                  style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                );
              }).toList(),
            ),
            const SizedBox(height: 80),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: (wordData['options'] as List<String>).map((opt) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedLetter = opt;
                    });
                    if (opt == wordData['letter']) {
                      AudioService().playSuccess();
                      _showSuccess();
                    } else {
                      AudioService().playError();
                      _showError();
                    }
                  },
                  child: Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.primaryColor, width: 3),
                      boxShadow: const [BoxShadow(color: Color(0xFF58A700), offset: Offset(0, 4))],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opt,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('¡GENIAL!')),
        content: const Icon(Icons.thumb_up, color: AppTheme.primaryColor, size: 80),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('CONTINUAR')),
        ],
      ),
    );
  }

  void _showError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Casi, intenta otra letra'), backgroundColor: AppTheme.accentColor),
    );
  }
}
