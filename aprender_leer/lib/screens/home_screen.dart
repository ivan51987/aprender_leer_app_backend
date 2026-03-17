import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme/app_theme.dart';
import 'lesson_screen.dart';
import 'letters_game_screen.dart';
import 'library_screen.dart';
import 'challenges_screen.dart';
import 'profile_screen.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  List<Map<String, dynamic>> _nodes = [
    // 1-5: Fundamentos
    {'id': 'letras', 'title': 'Letras Mágicas', 'level': 1, 'unlocked': true},
    {'id': 'vocales', 'title': 'Las Vocales', 'level': 2, 'unlocked': false},
    {'id': 'silabas_simples', 'title': 'Sílabas (M, P, T)', 'level': 3, 'unlocked': false},
    {'id': 'silabas_simples', 'title': 'Sílabas (C, S, L)', 'level': 4, 'unlocked': false},
    {'id': 'silabas_simples', 'title': 'Sílabas (N, D, R)', 'level': 5, 'unlocked': false},
    
    // 6-10: Primeras Palabras
    {'id': 'silabas_trabadas', 'title': 'Sílabas Trabadas', 'level': 6, 'unlocked': false},
    {'id': 'palabras_trabadas', 'title': 'Palabras Trabadas', 'level': 8, 'unlocked': false},
    {'id': 'palabras_casa_familia', 'title': 'Mi Familia', 'level': 10, 'unlocked': false},
    
    // 11-20: Vocabulario Temático
    {'id': 'palabras_animales', 'title': 'Los Animales', 'level': 12, 'unlocked': false},
    {'id': 'palabras_alimentos', 'title': 'Comida Rica', 'level': 15, 'unlocked': false},
    {'id': 'palabras_escuela', 'title': 'En la Escuela', 'level': 18, 'unlocked': false},
    {'id': 'palabras_ciudad', 'title': 'La Ciudad', 'level': 20, 'unlocked': false},
    
    // 21-30: Acciones y Vida
    {'id': 'palabras_naturaleza', 'title': 'Naturaleza', 'level': 22, 'unlocked': false},
    {'id': 'palabras_acciones', 'title': '¡A Moverse!', 'level': 25, 'unlocked': false},
    {'id': 'palabras_descripciones', 'title': 'Cómo es...', 'level': 28, 'unlocked': false},
    {'id': 'frases_cortas_1', 'title': 'Primeras Frases', 'level': 30, 'unlocked': false},
    
    // 31-40: Construcción de Frases
    {'id': 'frases_cortas_2', 'title': 'Frases de Animales', 'level': 33, 'unlocked': false},
    {'id': 'frases_cortas_3', 'title': 'Frases del Día', 'level': 36, 'unlocked': false},
    {'id': 'frases_preguntas', 'title': '¿Preguntas?', 'level': 38, 'unlocked': false},
    {'id': 'frases_exclamaciones', 'title': '¡Exclamaciones!', 'level': 40, 'unlocked': false},
    
    // 41-50: Lectura Avanzada
    {'id': 'frases_conversacion', 'title': 'Conversaciones', 'level': 43, 'unlocked': false},
    {'id': 'frases_emociones', 'title': 'Mis Emociones', 'level': 46, 'unlocked': false},
    {'id': 'frases_descripciones', 'title': 'Cuentos Largos', 'level': 50, 'unlocked': false},
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _PathView(nodes: _nodes),
      const LibraryScreen(),
      const ChallengesScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.lightGray, width: 2)),
      ),
      child: BottomNavigationBar(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Aprender'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book), label: 'Biblioteca'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Desafíos'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}

class _PathView extends StatefulWidget {
  final List<Map<String, dynamic>> nodes;
  const _PathView({required this.nodes});

  @override
  State<_PathView> createState() => _PathViewState();
}

class _PathViewState extends State<_PathView> {
  int _streak = 0;
  int _gems = 0;
  int _level = 1;
  Map<String, int> _categoryProgress = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final progress = ProgressService();
      final ninoId = await progress.getNinoId();
      if (ninoId != null) {
        final stats = await ApiService().getNinoStats(ninoId);
        if (mounted) {
          setState(() {
            _streak = stats['streak'] ?? 0;
            _gems = stats['gems'] ?? 0;
            _level = stats['level'] ?? 1;
            
            final progressMap = stats['category_progress'] as Map<String, dynamic>? ?? {};
            _categoryProgress = progressMap.map((key, value) => MapEntry(key, value as int));

            print('PathView: Stats cargadas: Nivel $_level, Gemas $_gems, Streak $_streak');
            
            // Update unlock status and stars in nodes
            for (var node in widget.nodes) {
              final nodeLevel = node['level'] as int;
              final categoryId = node['id'] as String;
              
              node['unlocked'] = (nodeLevel == 1) || (_level >= nodeLevel);
              node['stars'] = _categoryProgress[categoryId] ?? 0;
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            for (var node in widget.nodes) {
              if (node['level'] == 1) node['unlocked'] = true;
              node['stars'] = 0;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading stats in path view: $e');
    }
  }

  void _navigate(BuildContext context, Map<String, dynamic> node) {
    if (!(node['unlocked'] ?? false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Sigue practicando! Se desbloquea en el Nivel ${node['level']}'),
          backgroundColor: AppTheme.accentColor,
        ),
      );
      return;
    }

    final categoryId = node['id'] as String;
    final title = node['title'] as String;

    if (categoryId == 'letras') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LettersGameScreen())).then((_) => _loadStats());
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LessonScreen(categoryId: categoryId, title: title)),
      ).then((_) => _loadStats());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'NIVEL $_level',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          _buildTopStat(Icons.local_fire_department, '$_streak', Colors.orange),
          _buildTopStat(Icons.diamond, '$_gems', Colors.blue),
          const SizedBox(width: 8),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(color: AppTheme.lightGray, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 40),
          itemCount: widget.nodes.length,
          itemBuilder: (context, index) => _buildPathNode(context, index),
        ),
      ),
    );
  }

  Widget _buildTopStat(IconData icon, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildPathNode(BuildContext context, int index) {
    final node = widget.nodes[index];
    final isUnlocked = (node['unlocked'] as bool?) ?? false;
    final stars = (node['stars'] as int?) ?? 0;
    final title = node['title'] as String;

    // Color Logic
    Color nodeColor = AppTheme.lightGray;
    Color shadowColor = const Color(0xFFBDBDBD);
    
    if (isUnlocked) {
      if (stars >= 5) {
        nodeColor = const Color(0xFFFFD700); // Gold (5+)
        shadowColor = const Color(0xFFD4AF37);
      } else if (stars > 0) {
        nodeColor = const Color(0xFF58CC02); // Success Green (1-4)
        shadowColor = const Color(0xFF46A302);
      } else {
        nodeColor = AppTheme.primaryColor; // Active Blue (Unlocked 0 stars)
        shadowColor = const Color(0xFF58A700);
      }
    }
    
    print('Node $title: Unlocked=$isUnlocked, Stars=$stars, Color=$nodeColor');

    double screenWidth = MediaQuery.of(context).size.width;
    
    // Zigzag alignment
    double xPos = 0;
    if (index % 4 == 1) xPos = 60;
    if (index % 4 == 2) xPos = 0;
    if (index % 4 == 3) xPos = -60;

    return FadeInUp(
      delay: Duration(milliseconds: index * 80),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: Center(
          child: Transform.translate(
            offset: Offset(xPos, 0),
            child: GestureDetector(
              onTap: () => _navigate(context, node),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Node Circle
                      Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          color: nodeColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: shadowColor,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Icon(
                          isUnlocked ? _nodeIcon(index) : Icons.lock,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      // Label Box
                      Positioned(
                        top: -35,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.lightGray, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w900, 
                              fontSize: 13,
                              color: isUnlocked ? AppTheme.textColor : Colors.grey,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      // Stars Indicator
                      if (isUnlocked && stars > 0)
                        Positioned(
                          bottom: -22,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) => Icon(
                              Icons.star,
                              size: 16,
                              color: i < stars ? const Color(0xFFFFD700) : Colors.grey.withOpacity(0.3),
                            )),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _nodeIcon(int index) {
    if (index == 0) return Icons.abc;
    if (index < 5) return Icons.record_voice_over_rounded;
    if (index < 10) return Icons.spellcheck_rounded;
    if (index < 20) return Icons.auto_awesome_rounded;
    if (index < 30) return Icons.directions_run_rounded;
    if (index < 40) return Icons.forum_rounded;
    return Icons.menu_book_rounded;
  }
}
