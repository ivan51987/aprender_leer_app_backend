import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme/app_theme.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import '../games/listen_select_game.dart';
import '../games/audio_match_game.dart';

/// Central lesson screen inspired by Duolingo.
/// Loads data from the backend and sequences exercises.
class LessonScreen extends StatefulWidget {
  final String categoryId;
  final String title;

  const LessonScreen({super.key, required this.categoryId, required this.title});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  bool _loading = true;
  String? _error;
  List<CategoryItem> _items = [];
  List<QuizQuestion> _quiz = [];
  int _level = 1;
  int _lastStars = 0;

  // 0 = intro, 1 = ListenSelect, 2 = AudioMatch, 3 = finish
  int _phase = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final progress = ProgressService();
      final ninoId = await progress.getNinoId();
      
      final results = await Future.wait([
        ApiService().getLesson(widget.categoryId),
        ApiService().getQuiz(widget.categoryId),
        if (ninoId != null) ApiService().getNinoStats(ninoId) else Future.value({'level': 1}),
      ]);
      
      _items = results[0] as List<CategoryItem>;
      _quiz = results[1] as List<QuizQuestion>;
      if (ninoId != null) {
        _level = (results[2] as Map<String, dynamic>)['level'] ?? 1;
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Cargando lección...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'No se pudo conectar al servidor',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('REINTENTAR'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    switch (_phase) {
      case 0:
        return _buildIntroPhase();
      case 1:
        return ListenSelectGame(
          questions: _quiz,
          onComplete: (stars) {
            _saveScore(stars); // Save actual performance
            setState(() {
              _lastStars = stars;
              _phase = 2;
            });
          },
        );
      case 2:
        return AudioMatchGame(
          items: _items,
          onComplete: () {
            _saveScore(5); // AudioMatch is discovery/completion based
            setState(() {
              _lastStars = 5;
              _phase = 3;
            });
          },
        );
      case 3:
        return _buildFinishPhase();
      default:
        return _buildIntroPhase();
    }
  }

  Future<void> _saveScore(int stars) async {
    try {
      final progress = ProgressService();
      final ninoId = await progress.getNinoId();
      if (ninoId != null) {
        // Difficulty scaling: more points for higher levels
        // Base 20 pts/star, increases with level
        final multiplier = 20 + (_level - 1) * 5;
        await ApiService().saveScore(
          ninoId: ninoId,
          category: widget.categoryId,
          gameType: 'lesson',
          score: stars * multiplier,
          stars: stars,
        );
      }
    } catch (e) {
      debugPrint('Error saving score: $e');
    }
  }

  Widget _buildIntroPhase() {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Spacer(),
            FadeInDown(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.menu_book_rounded, size: 60, color: Colors.white),
              ),
            ),
            const SizedBox(height: 28),
            FadeInUp(
              delay: const Duration(milliseconds: 150),
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 250),
              child: Text(
                '${_items.length} elementos · 2 ejercicios',
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
            ),
            const SizedBox(height: 32),
            FadeInUp(
              delay: const Duration(milliseconds: 350),
              child: _buildExercisePill(Icons.headphones_rounded, 'Escucha y Elige', AppTheme.secondaryColor),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 450),
              child: _buildExercisePill(Icons.grid_view_rounded, 'Une el Audio', AppTheme.warningColor),
            ),
            const Spacer(),
            FadeInUp(
              delay: const Duration(milliseconds: 550),
              child: ElevatedButton(
                onPressed: () => setState(() => _phase = 1),
                child: const Text('¡EMPEZAR LECCIÓN!'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisePill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFinishPhase() {
    final starsEarned = _lastStars;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              ZoomIn(
                child: const Icon(Icons.emoji_events_rounded, size: 100, color: AppTheme.warningColor),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                child: const Text(
                  '¡Lección Completada!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ElasticIn(
                        delay: Duration(milliseconds: 300 + i * 150),
                        child: Icon(
                          Icons.star_rounded,
                          size: 52,
                          color: i < starsEarned ? AppTheme.warningColor : AppTheme.lightGray,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('¡CONTINUAR!'),
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: TextButton(
                  onPressed: () {
                    setState(() => _phase = 0);
                  },
                  child: const Text('Repetir lección', style: TextStyle(color: Colors.grey)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
