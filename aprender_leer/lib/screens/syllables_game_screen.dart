import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';
import '../widgets/syllable_button.dart';

class SyllablesGameScreen extends StatefulWidget {
  const SyllablesGameScreen({super.key});

  @override
  State<SyllablesGameScreen> createState() => _SyllablesGameScreenState();
}

class _SyllablesGameScreenState extends State<SyllablesGameScreen> {
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
      _items = await ApiService().getLesson('silabas_simples');
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Juega con Sílabas')),
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
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      alignment: WrapAlignment.center,
                      children: _items.map((item) => SyllableButton(
                        syllable: item.text.toUpperCase(),
                        onTap: () => AudioService().playUrl(item.audioUrl),
                      )).toList(),
                    ),
                  ),
                ),
    );
  }
}
