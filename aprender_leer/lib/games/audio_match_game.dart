import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../models/api_models.dart';
import '../services/audio_service.dart';
import '../core/theme/app_theme.dart';

class AudioMatchGame extends StatefulWidget {
  final List<CategoryItem> items;
  final VoidCallback? onComplete;

  const AudioMatchGame({
    super.key,
    required this.items,
    this.onComplete,
  });

  @override
  State<AudioMatchGame> createState() => _AudioMatchGameState();
}

class _AudioMatchGameState extends State<AudioMatchGame> {
  late List<CategoryItem> _displayItems;
  String? _selectedId;
  final Set<String> _matched = {};

  @override
  void initState() {
    super.initState();
    _displayItems = (widget.items.toList()..shuffle()).take(8).toList();
  }

  Future<void> _onTapCard(CategoryItem item) async {
    // Play audio on every tap
    if (item.audioUrl.isNotEmpty) {
      await AudioService().playUrl(item.audioUrl);
    }

    if (_matched.contains(item.id)) return;

    setState(() {
      if (_selectedId == null) {
        _selectedId = item.id;
      } else if (_selectedId == item.id) {
        // Tapped same card twice → deselect
        _selectedId = null;
      } else {
        // Two different cards selected — in this game the audio plays
        // and the user confirms by tapping the same card again
        _selectedId = item.id;
      }
    });
  }

  /// The user taps the "Confirmar" button after hearing the audio.
  void _confirmMatch(CategoryItem item) {
    if (_matched.contains(item.id)) return;
    setState(() {
      _matched.add(item.id);
      _selectedId = null;
    });
    AudioService().playSuccess();

    if (_matched.length == _displayItems.length) {
      Future.delayed(const Duration(milliseconds: 600), _showResultDialog);
    }
  }

  void _showResultDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => FadeInUp(
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Center(
            child: Text(
              '¡Completado! 🎊',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: AppTheme.warningColor, size: 72),
              const SizedBox(height: 12),
              Text(
                '¡Reconociste ${_displayItems.length} letras!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onComplete?.call();
              },
              child: const Text('CONTINUAR'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Une el Audio', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(14),
          child: LinearProgressIndicator(
            value: _matched.length / _displayItems.length,
            color: AppTheme.primaryColor,
            backgroundColor: AppTheme.lightGray,
            minHeight: 10,
          ),
        ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Toca una tarjeta para escuchar su sonido',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppTheme.textColor),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cols = constraints.maxWidth > 600 ? 5 : 4;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _displayItems.length,
                      itemBuilder: (context, index) {
                        final item = _displayItems[index];
                        final isMatched = _matched.contains(item.id);
                        final isSelected = _selectedId == item.id;
      
                        return FadeInUp(
                          delay: Duration(milliseconds: index * 40),
                          child: GestureDetector(
                            onTap: () => _onTapCard(item),
                            onDoubleTap: () => _confirmMatch(item),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                              decoration: BoxDecoration(
                                color: isMatched
                                    ? AppTheme.primaryColor.withOpacity(0.15)
                                    : isSelected
                                        ? AppTheme.secondaryColor.withOpacity(0.15)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isMatched
                                      ? AppTheme.primaryColor
                                      : isSelected
                                          ? AppTheme.secondaryColor
                                          : AppTheme.lightGray,
                                  width: 2.5,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (isMatched)
                                    const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 24)
                                  else
                                    Icon(
                                      Icons.volume_up_rounded,
                                      color: isSelected ? AppTheme.secondaryColor : Colors.grey.shade400,
                                      size: 24,
                                    ),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      item.text.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isMatched
                                            ? AppTheme.primaryColor
                                            : isSelected
                                                ? AppTheme.secondaryColor
                                                : AppTheme.textColor,
                                      ),
                                    ),
                                  ),
                                  if (isSelected && !isMatched)
                                    const Text(
                                      '2×',
                                      style: TextStyle(fontSize: 8, color: Colors.grey),
                                      textAlign: TextAlign.center,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
