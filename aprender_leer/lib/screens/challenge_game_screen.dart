import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import '../services/audio_service.dart';
import 'dart:math';

class ChallengeGameScreen extends StatefulWidget {
  final String gameType;
  const ChallengeGameScreen({super.key, required this.gameType});

  @override
  State<ChallengeGameScreen> createState() => _ChallengeGameScreenState();
}

class _ChallengeGameScreenState extends State<ChallengeGameScreen> {
  bool _loading = true;
  String _word = '';
  
  // Completar Palabras State
  String _hiddenLetter = '';
  int _hiddenIndex = -1;
  List<String> _options = [];
  
  // Sopa de Letras State
  List<List<String>> _grid = [];
  List<Point<int>> _selectedPoints = [];
  List<Point<int>> _correctPoints = [];

  bool _answered = false;
  bool _isCorrect = false;

  @override
  void initState() {
    super.initState();
    _nextChallenge();
  }

  Future<void> _nextChallenge() async {
    setState(() {
      _loading = true;
      _answered = false;
      _selectedPoints = [];
      _correctPoints = [];
    });

    try {
      final categories = await ApiService().getCategories();
      final validCats = categories.where((c) => !c.id.contains('frases') && !c.id.contains('cuento')).toList();
      final cat = validCats[Random().nextInt(validCats.length)];
      final items = await ApiService().getLesson(cat.id);
      final item = items[Random().nextInt(items.length)];
      
      String word = item.text.toUpperCase().replaceAll(' ', ''); 
      if (word.length < 3 || word.length > 6) return _nextChallenge(); 

      if (widget.gameType == 'completar') {
        _initCompletar(word);
      } else {
        _initSopa(word);
      }
    } catch (e) {
      debugPrint('Error starting challenge: $e');
    }
  }

  void _initCompletar(String word) {
    int index = Random().nextInt(word.length);
    String hidden = word[index];
    List<String> options = [hidden];
    String alphabet = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ';
    while (options.length < 3) {
      String rand = alphabet[Random().nextInt(alphabet.length)];
      if (!options.contains(rand)) options.add(rand);
    }
    options.shuffle();

    setState(() {
      _word = word;
      _hiddenLetter = hidden;
      _hiddenIndex = index;
      _options = options;
      _loading = false;
    });
  }

  void _initSopa(String word) {
    int size = 6;
    _grid = List.generate(size, (_) => List.generate(size, (_) => ''));
    String alphabet = 'ABCDEFGHIJKLMNÑOPQRSTUVWXYZ';
    
    // Pick direction: 0 horizontal, 1 vertical
    int dir = Random().nextInt(2);
    int r, c;
    if (dir == 0) { // Horizontal
      r = Random().nextInt(size);
      c = Random().nextInt(size - word.length + 1);
    } else { // Vertical
      r = Random().nextInt(size - word.length + 1);
      c = Random().nextInt(size);
    }

    _correctPoints = [];
    for (int i = 0; i < word.length; i++) {
      int currR = (dir == 0) ? r : r + i;
      int currC = (dir == 0) ? c + i : c;
      _grid[currR][currC] = word[i];
      _correctPoints.add(Point(currR, currC));
    }

    // Fill the rest
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        if (_grid[i][j] == '') {
          _grid[i][j] = alphabet[Random().nextInt(alphabet.length)];
        }
      }
    }

    setState(() {
      _word = word;
      _loading = false;
    });
  }

  void _checkAnswer(String letter) async {
    if (_answered) return;

    setState(() {
      _answered = true;
      _isCorrect = (letter == _hiddenLetter);
    });

    if (_isCorrect) {
      AudioService().playSuccess();
      final pid = await ProgressService().getNinoId();
      if (pid != null) {
        // Reward 5 stars and 100 points
        await ApiService().saveScore(
          ninoId: pid,
          category: 'desafio_interactivo',
          gameType: 'Completar-$_word',
          score: 100,
          stars: 5,
        );
      }
    } else {
      // AudioService().playError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
        title: const Text('DESAFÍO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: Colors.white))
        : SizedBox.expand(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (widget.gameType == 'completar') _buildCompletarGame(),
                    if (widget.gameType == 'sopa') _buildSopaGame(),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildCompletarGame() {
    return Column(
      children: [
        FadeInDown(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                const Text('¿QUÉ LETRA FALTA?', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 40),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 16,
                  children: List.generate(_word.length, (i) {
                    bool isHidden = (i == _hiddenIndex);
                    if (_word[i] == ' ') return const SizedBox(width: 20);
                    return Container(
                      padding: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: isHidden ? AppTheme.accentColor : Colors.black, width: 4)),
                      ),
                      child: Text(
                        isHidden ? (_answered ? _hiddenLetter : '?') : _word[i],
                        style: TextStyle(
                          fontSize: _word.length > 10 ? 24 : 36, 
                          fontWeight: FontWeight.bold, 
                          color: isHidden && _answered ? (_isCorrect ? Colors.green : Colors.red) : Colors.black
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 60),
        if (!_answered)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: _options.map((opt) => FadeInUp(
              child: GestureDetector(
                onTap: () => _checkAnswer(opt),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: Text(opt, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  ),
                ),
              ),
            )).toList(),
          ),
        if (_answered) _buildResultView(),
      ],
    );
  }

  Widget _buildSopaGame() {
    return Column(
      children: [
        FadeInDown(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              children: [
                const Text('BUSCA LA PALABRA:', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 2)),
                const SizedBox(height: 16),
                Text(_word, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 4)),
                const SizedBox(height: 24),
                // Grid
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.lightGray.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: 36,
                    itemBuilder: (context, index) {
                      int r = index ~/ 6;
                      int c = index % 6;
                      Point<int> p = Point(r, c);
                      bool isSelected = _selectedPoints.contains(p);
                      bool isCorrect = _correctPoints.contains(p);
                      
                      Color cellColor = Colors.white;
                      if (_answered) {
                        if (isCorrect) cellColor = Colors.green.withValues(alpha: 0.2);
                        else if (isSelected) cellColor = Colors.red.withValues(alpha: 0.2);
                      } else if (isSelected) {
                        cellColor = AppTheme.secondaryColor.withValues(alpha: 0.3);
                      }

                      return GestureDetector(
                        onTap: () => _togglePoint(p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: cellColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? AppTheme.secondaryColor : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _grid[r][c],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppTheme.secondaryColor : AppTheme.textColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        if (!_answered)
          ElevatedButton(
            onPressed: _selectedPoints.length == _word.length ? _checkSopa : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 5,
            ),
            child: const Text('VERIFICAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ),
        if (_answered) _buildResultView(),
      ],
    );
  }

  void _togglePoint(Point<int> p) {
    if (_answered) return;
    setState(() {
      if (_selectedPoints.contains(p)) {
        _selectedPoints.remove(p);
      } else if (_selectedPoints.length < _word.length) {
        _selectedPoints.add(p);
      }
    });
  }

  void _checkSopa() async {
    bool correct = true;
    for (var p in _correctPoints) {
      if (!_selectedPoints.contains(p)) {
        correct = false;
        break;
      }
    }

    setState(() {
      _answered = true;
      _isCorrect = correct;
    });

    if (_isCorrect) {
      AudioService().playSuccess();
      final pid = await ProgressService().getNinoId();
      if (pid != null) {
        await ApiService().saveScore(
          ninoId: pid,
          category: 'desafio_interactivo',
          gameType: 'Sopa-$_word',
          score: 100,
          stars: 5,
        );
      }
    }
  }

  Widget _buildResultView() {
    return FadeIn(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _isCorrect ? '¡FANTÁSTICO!' : '¡CASI! ERA LA "$_hiddenLetter"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _nextChallenge,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: Text(
              'SIGUIENTE',
              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}
