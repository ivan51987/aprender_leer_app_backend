import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../models/api_models.dart';
import '../services/audio_service.dart';
import '../core/theme/app_theme.dart';

class ListenSelectGame extends StatefulWidget {
  final List<QuizQuestion> questions;
  final Function(int)? onComplete;

  const ListenSelectGame({
    super.key,
    required this.questions,
    this.onComplete,
  });

  @override
  State<ListenSelectGame> createState() => _ListenSelectGameState();
}

class _ListenSelectGameState extends State<ListenSelectGame> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  int _lives = 5;
  int _score = 0;
  String? _selectedAnswer;
  bool _answered = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 12).chain(
      CurveTween(curve: Curves.elasticIn),
    ).animate(_shakeController);
    WidgetsBinding.instance.addPostFrameCallback((_) => _playCurrentAudio());
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  QuizQuestion get _currentQuestion => widget.questions[_currentIndex];

  Future<void> _playCurrentAudio() async {
    if (_currentQuestion.audioUrl.isNotEmpty) {
      await AudioService().playUrl(_currentQuestion.audioUrl);
    }
  }

  void _selectAnswer(String answer) {
    if (_answered) return;
    setState(() {
      _selectedAnswer = answer;
      _answered = true;
    });

    final isCorrect = answer == _currentQuestion.correctAnswer;
    if (isCorrect) {
      _score++;
      AudioService().playSuccess();
    } else {
      _lives = (_lives - 1).clamp(0, 5);
      AudioService().playError();
      _shakeController.forward(from: 0);
    }

    Future.delayed(const Duration(milliseconds: 1200), _nextQuestion);
  }

  void _nextQuestion() {
    if (!mounted) return;
    if (_currentIndex < widget.questions.length - 1 && _lives > 0) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _answered = false;
      });
      _playCurrentAudio();
    } else {
      _showResultDialog();
    }
  }

  void _showResultDialog() {
    final totalQ = widget.questions.length;
    final starsEarned = _lives;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FadeInUp(
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Center(
            child: Text(
              _score >= totalQ ~/ 2 ? '¡Excelente! 🎉' : '¡Sigue intentando!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _score >= totalQ ~/ 2 ? AppTheme.primaryColor : AppTheme.accentColor,
              ),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => Icon(
                  Icons.star,
                  size: 40,
                  color: i < starsEarned ? AppTheme.warningColor : AppTheme.lightGray,
                )),
              ),
              const SizedBox(height: 16),
              Text(
                '$_score / $totalQ correctas',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onComplete?.call(starsEarned);
              },
              child: const Text('CONTINUAR'),
            ),
          ],
        ),
      ),
    );
  }

  Color _optionColor(String option) {
    if (!_answered) return Colors.white;
    if (option == _currentQuestion.correctAnswer) return const Color(0xFFD7FFB8);
    if (option == _selectedAnswer) return const Color(0xFFFFDDDD);
    return Colors.white;
  }

  Color _optionBorderColor(String option) {
    if (!_answered) return AppTheme.lightGray;
    if (option == _currentQuestion.correctAnswer) return AppTheme.primaryColor;
    if (option == _selectedAnswer) return AppTheme.accentColor;
    return AppTheme.lightGray;
  }

  @override
  Widget build(BuildContext context) {
    final q = _currentQuestion;
    final progress = (_currentIndex + 1) / widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.lightGray,
          color: AppTheme.primaryColor,
          minHeight: 14,
          borderRadius: BorderRadius.circular(7),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: List.generate(
                5,
                (i) => Icon(
                  Icons.favorite,
                  color: i < _lives ? AppTheme.accentColor : AppTheme.lightGray,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '¿Qué letra / sílaba escuchas?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Play audio button
            Center(
              child: AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) => Transform.translate(
                  offset: Offset(_shakeAnimation.value * (_answered && _selectedAnswer != q.correctAnswer ? 1 : 0), 0),
                  child: child,
                ),
                child: InkWell(
                  onTap: _playCurrentAudio,
                  borderRadius: BorderRadius.circular(60),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: Colors.white, size: 56),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Toca para escuchar de nuevo', style: TextStyle(color: Colors.grey, fontSize: 13)),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Scrollbar(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 2.0,
                  padding: const EdgeInsets.only(bottom: 20),
                  children: q.options.map((option) {
                    final isCorrect = _answered && option == q.correctAnswer;
                    final isWrong = _answered && option == _selectedAnswer && option != q.correctAnswer;
                    return GestureDetector(
                      onTap: () => _selectAnswer(option),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        decoration: BoxDecoration(
                          color: _optionColor(option),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _optionBorderColor(option), width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: _answered
                                  ? (isCorrect ? AppTheme.primaryColor : isWrong ? AppTheme.accentColor : Colors.transparent)
                                  : const Color(0xFF58A700),
                              offset: const Offset(0, 4),
                              blurRadius: _answered ? 0 : 2,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isCorrect) Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18)),
                            if (isWrong) Padding(padding: const EdgeInsets.only(right: 4), child: Icon(Icons.cancel, color: AppTheme.accentColor, size: 18)),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  option.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isCorrect
                                        ? AppTheme.primaryColor
                                        : isWrong
                                            ? AppTheme.accentColor
                                            : AppTheme.textColor,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
