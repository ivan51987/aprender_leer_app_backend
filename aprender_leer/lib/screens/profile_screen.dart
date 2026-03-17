import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import 'register_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  int _level = 1;
  int _streak = 0;
  int _gems = 0;
  int _totalStars = 0;
  int _starsAprender = 0;
  int _starsBiblioteca = 0;
  int _starsDesafios = 0;
  int _rank = 0;
  List<dynamic> _leaderboard = [];
  String _nombre = 'Amiguito';
  String _apellidos = '';

  @override
  void initState() {
    super.initState();
    loadStats();
  }

  Future<void> loadStats() async {
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
          final apellidosFromApi = (stats['apellidos'] ?? '').toString().trim();
          final nombreFromApi = (stats['nombre'] ?? _nombre).toString().trim();
          setState(() {
            _nombre = nombreFromApi;
            _apellidos = apellidosFromApi;
            _level = stats['level'] ?? 1;
            _streak = stats['streak'] ?? 0;
            _gems = stats['gems'] ?? 0;
            _totalStars = stats['totalStars'] ?? 0;
            _starsAprender = stats['starsAprender'] ?? 0;
            _starsBiblioteca = stats['starsBiblioteca'] ?? 0;
            _starsDesafios = stats['starsDesafios'] ?? 0;
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
          IconButton(onPressed: loadStats, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator())
        : Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
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
                          '¡Hola, ${_apellidos.isNotEmpty ? '$_nombre $_apellidos' : _nombre}!', 
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        if (_rank > 0)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryColor.withOpacity(0.1),
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
                  
                  Row(
                    children: [
                       Expanded(child: _buildStatCard('Nivel', _level.toString(), Icons.trending_up, Colors.blue)),
                       const SizedBox(width: 12),
                       Expanded(child: _buildStatCard('Gemas', _gems.toString(), Icons.diamond, Colors.purple)),
                       const SizedBox(width: 12),
                       Expanded(child: _buildStatCard('Racha', '$_streak d', Icons.local_fire_department, Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 24),
    
                  // Star Breakdown Card
                  _buildStarBreakdown(),
    
                  const SizedBox(height: 32),
                  const Text('TABLA DE POSICIONES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
                  const SizedBox(height: 16),
                  _buildLeaderboard(),
    
                  const SizedBox(height: 48),
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
            ),
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
          final fullName = (item['nombre_completo'] ?? item['nombre'] ?? '').toString();
          bool isMe = (fullName.isNotEmpty && fullName == '${_nombre}${_apellidos.isNotEmpty ? ' $_apellidos' : ''}');
          
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
                      Text(fullName, style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.w500, fontSize: 16)),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStarBreakdown() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
        border: Border.all(color: AppTheme.lightGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ESTRELLAS GANADAS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.warningColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text('$_totalStars TOTAL', style: const TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStarRow('Aprender', _starsAprender, AppTheme.primaryColor),
          const Divider(height: 24),
          _buildStarRow('Biblioteca', _starsBiblioteca, Colors.green),
          const Divider(height: 24),
          _buildStarRow('Desafíos', _starsDesafios, Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStarRow(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.star_rounded, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
