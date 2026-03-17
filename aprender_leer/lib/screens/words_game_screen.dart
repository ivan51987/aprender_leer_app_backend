import 'package:flutter/material.dart';
import '../widgets/game_button.dart';
import '../games/word_builder_game.dart';

class WordsGameScreen extends StatelessWidget {
  const WordsGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forma Palabras')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Expanded(
                child: Center(
                  child: Text('¿Listo para el desafío?', style: TextStyle(fontSize: 24)),
                ),
              ),
              GameButton(
                label: 'EMPEZAR JUEGO',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WordScrambleGame()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
