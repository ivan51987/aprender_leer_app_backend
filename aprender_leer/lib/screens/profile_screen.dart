import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  int _level = 1;
  int _streak = 0;
  int _gems = 0;
  int _rank = 0;
  List<dynamic> _leaderboard = [];
  String _nombre = 'Amiguito';

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final progress = ProgressService();
      final ninoId = await progress.getNinoId();
      _nombre = await progress.getNinoNombre() ?? 'Amiguito';
      
      if (ninoId != null) {
        final results = await Future.wait<dynamic>([
          ApiService().getNinoStats(ninoId),
          ApiService().getNinoRank(ninoId),
          ApiService().getLeaderboard(),
        ]);

        final stats = results[0] as Map<String, dynamic>;
        
        if (mounted) {
          setState(() {
            _level = stats['level'] ?? 1;
            _streak = stats['streak'] ?? 0;
            _gems = stats['gems'] ?? 0;
            _rank = (results[1] as int?) ?? 0;
            _leaderboard = results[2] as List<dynamic>;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    await ProgressService().logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PERFIL', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: _loadStats, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 50,
                      backgroundColor: AppTheme.lightGray,
                      child: Icon(Icons.person, size: 60, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '¡Hola, $_nombre!', 
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    if (_rank > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Puesto #$_rank Global',
                          style: TextStyle(color: AppTheme.secondaryColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              const Text('MIS ESTADÍSTICAS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              _buildProfileItem(Icons.star, 'Nivel $_level', Colors.amber),
              _buildProfileItem(Icons.local_fire_department, 'Racha de $_streak días', Colors.orange),
              _buildProfileItem(Icons.diamond, '$_gems Gemas', Colors.blue),
              
              const SizedBox(height: 40),
              const Text('TABLA DE POSICIONES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
              const SizedBox(height: 16),
              _buildLeaderboard(),

              const SizedBox(height: 40),
              Center(
                child: Text(
                  'Creado por: Ing. Ivan Flores Flores',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => _logout(context),
                icon: const Icon(Icons.logout),
                label: const Text('CERRAR SESIÓN'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
    );
  }

  Widget _buildLeaderboard() {
    if (_leaderboard.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Text('¡Sé el primero en la tabla!', style: TextStyle(color: Colors.grey)),
      ));
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        children: _leaderboard.asMap().entries.map((entry) {
          int idx = entry.key;
          var item = entry.value;
          bool isMe = (item['nombre'] == _nombre);
          
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? AppTheme.primaryColor.withValues(alpha: 0.05) : null,
              border: idx < _leaderboard.length - 1 ? const Border(bottom: BorderSide(color: AppTheme.lightGray)) : null,
            ),
            child: Row(
              children: [
                _buildRankBadge(idx + 1),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['nombre'], style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.w500, fontSize: 16)),
                      Text('Nivel ${item['level']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${item['total_stars']}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningColor)),
                    const Text('estrellas', style: TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color badgeColor = Colors.grey;
    if (rank == 1) badgeColor = Colors.amber;
    if (rank == 2) badgeColor = const Color(0xFFC0C0C0);
    if (rank == 3) badgeColor = const Color(0xFFCD7F32);

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
      child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildProfileItem(IconData icon, String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
