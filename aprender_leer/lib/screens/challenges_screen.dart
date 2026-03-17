import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import 'challenge_game_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => ChallengesScreenState();
}

class ChallengesScreenState extends State<ChallengesScreen> {
  int _gems = 0;
  int _totalStars = 0;
  int _level = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
    try {
      final pid = await ProgressService().getNinoId();
      if (pid != null) {
        final stats = await ApiService().getNinoStats(pid);
        setState(() {
          _gems = stats['gems'] ?? 0;
          _totalStars = stats['totalStars'] ?? 0;
          _level = stats['level'] ?? 1;
        });
      }
    } catch (e) {
      debugPrint('Error loading challenges: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('DESAFÍOS', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: loadStats,
        child: _loading 
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                child: ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Stats Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniStat(Icons.diamond, '$_gems', Colors.blue),
                        _buildMiniStat(Icons.trending_up, 'NVL $_level', Colors.orange),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    Text(
                      'DESAFÍOS INTERACTIVOS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 16),
                    
                    _buildChallengeButton(
                      'COMPLETAR PALABRAS',
                      'Encuentra la letra que falta',
                      Icons.extension,
                      Colors.purple,
                      () => _startChallenge('completar'),
                    ),
                    const SizedBox(height: 12),
                    _buildChallengeButton(
                      'SOPA DE LETRAS',
                      'Busca palabras ocultas',
                      Icons.grid_on,
                      Colors.teal,
                      () => _startChallenge('sopa'),
                    ),
                    
                    const SizedBox(height: 40),
                    Text(
                      'MISIONES DIARIAS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textColor, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 16),
                    _buildMissionCard(
                      'Camino al Éxito',
                      'Llega al Nivel 50',
                      (_level / 50).clamp(0.0, 1.0),
                      Icons.trending_up,
                      AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 16),
                    _buildMissionCard(
                      'Coleccionista de Estrellas',
                      'Gana 250 estrellas en total',
                      (_totalStars / 250).clamp(0.0, 1.0),
                      Icons.star,
                      AppTheme.warningColor,
                    ),
                  ],
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildChallengeButton(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return FadeInLeft(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                child: Icon(icon, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _startChallenge(String type) {
    if (type == 'completar') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChallengeGameScreen(gameType: 'completar')),
      ).then((_) => loadStats());
    } else if (type == 'sopa') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChallengeGameScreen(gameType: 'sopa')),
      ).then((_) => loadStats());
    }
  }

  Widget _buildMissionCard(String title, String desc, double progress, IconData icon, Color color) {
    return FadeInRight(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.lightGray, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text(desc, style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: AppTheme.lightGray,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${(progress * 100).toInt()}%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
