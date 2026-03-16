import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../services/progress_service.dart';
import '../widgets/letter_card.dart';

class LettersGameScreen extends StatefulWidget {
  const LettersGameScreen({super.key});

  @override
  State<LettersGameScreen> createState() => _LettersGameScreenState();
}

class _LettersGameScreenState extends State<LettersGameScreen> {
  List<CategoryItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      _items = await ApiService().getLesson('letras');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finishLesson() async {
    try {
      final progress = ProgressService();
      final ninoId = await progress.getNinoId();
      if (ninoId != null) {
        // Award 100 points and 5 stars
        await ApiService().saveScore(
          ninoId: ninoId,
          category: 'letras',
          gameType: 'discovery',
          score: 100,
          stars: 5,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Excelente! Has ganado 5 estrellas')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error finishing letters lesson: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descubre las Letras')),
      floatingActionButton: _loading || _error != null || _items.isEmpty 
        ? null 
        : FloatingActionButton.extended(
            onPressed: _finishLesson,
            icon: const Icon(Icons.check_circle),
            label: const Text('¡Terminar!'),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(_error!, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(onPressed: _load, child: const Text('REINTENTAR')),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return LetterCard(
                      letter: item.text.toUpperCase(),
                      onTap: () => AudioService().playUrl(item.audioUrl),
                    );
                  },
                ),
    );
  }
}
