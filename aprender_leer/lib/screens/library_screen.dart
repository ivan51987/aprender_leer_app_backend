import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../core/theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/progress_service.dart';
import '../services/audio_service.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<dynamic> _sections = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLibrary();
  }

  Future<void> _loadLibrary() async {
    try {
      final categories = await ApiService().getCategories();
      // Filter for phrases and stories
      final filtered = categories.where((c) => c.id.contains('frases') || c.id.contains('cuento')).toList();
      
      setState(() {
        _sections = filtered;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading library: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('FRASES Y CUENTOS', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _loadLibrary,
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: _loading 
              ? const Center(child: CircularProgressIndicator())
              : _sections.isEmpty
                ? _buildEmptyState()
                : _buildGallery(),
          ),
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book, size: 80, color: AppTheme.lightGray),
          const SizedBox(height: 16),
          const Text('Aún no hay cuentos disponibles', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _sections.length,
      itemBuilder: (context, index) {
        final section = _sections[index];
        return FadeInUp(
          delay: Duration(milliseconds: index * 100),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(section.id.contains('cuento') ? Icons.auto_stories : Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        section.label.toUpperCase(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textColor, letterSpacing: 1.2),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: section.items.length,
                    itemBuilder: (context, i) {
                      final item = section.items[i];
                      return _buildItemCard(section.id, item, i);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildItemCard(String categoryId, dynamic item, int index) {
    String title = item.text;
    // For stories, show a snippet
    if (title.length > 50) title = "${title.substring(0, 47)}...";

    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => _openLearningView(categoryId, index),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.lightGray, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_circle_fill, size: 42, color: AppTheme.primaryColor),
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textColor, fontSize: 13),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLearningView(String categoryId, int index) async {
    // Fetch items for this category
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => _LearningDialog(categoryId: categoryId, initialIndex: index),
    ).then((_) => _loadLibrary()); // Refresh gems/stats if needed
  }
}

class _LearningDialog extends StatefulWidget {
  final String categoryId;
  final int initialIndex;
  const _LearningDialog({required this.categoryId, this.initialIndex = 0});

  @override
  State<_LearningDialog> createState() => _LearningDialogState();
}

class _LearningDialogState extends State<_LearningDialog> {
  List<dynamic> _items = [];
  late int _currentIndex;
  bool _loading = true;
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final items = await ApiService().getLesson(widget.categoryId);
      setState(() {
        _items = items;
        _loading = false;
      });
      _playCurrentItemAudio();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _claimReward() async {
    if (_rewarded) return;
    
    final progress = ProgressService();
    final pid = await progress.getNinoId();
    if (pid != null) {
      final currentItem = _items[_currentIndex];
      try {
        await ApiService().learnItem(pid, widget.categoryId, currentItem.text);
        AudioService().playSuccess();
        setState(() => _rewarded = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Excelente! +1 Estrella ganada'), backgroundColor: Colors.green),
        );
      } catch (e) {
        debugPrint('Error claiming reward: $e');
      }
    }
  }

  void _playCurrentItemAudio() {
    if (_items.isEmpty) return;
    final item = _items[_currentIndex];
    if (item.audioUrl != null) {
      AudioService().playUrl(item.audioUrl!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const AlertDialog(title: Text('No hay contenido'));

    final item = _items[_currentIndex];

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('APRENDIENDO', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                item.text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textColor),
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  if (item.audioUrl.isNotEmpty) {
                    AudioService().playUrl(item.audioUrl);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                  child: const Icon(Icons.volume_up, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _rewarded ? null : _claimReward,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _rewarded ? Colors.grey : AppTheme.accentColor,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(
                  _rewarded ? '¡YA APRENDIDO!' : '¡LO APRENDÍ! (Gana Gemas)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: _currentIndex > 0 ? () => setState(() { 
                      _currentIndex--; 
                      _rewarded = false; 
                      _playCurrentItemAudio();
                    }) : null,
                  ),
                  Text('${_currentIndex + 1} de ${_items.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: _currentIndex < _items.length - 1 ? () => setState(() { 
                      _currentIndex++; 
                      _rewarded = false; 
                      _playCurrentItemAudio();
                    }) : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
