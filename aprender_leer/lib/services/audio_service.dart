import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  final AudioPlayer _effectPlayer = AudioPlayer();
  final AudioPlayer _bgPlayer = AudioPlayer();

  factory AudioService() => _instance;

  AudioService._internal();

  Future<void> playEffect(String path) async {
    try {
      await _effectPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint('AudioService: No se pudo reproducir $path — $e');
    }
  }

  /// Play an MP3 directly from a URL (e.g., from the letras_voz backend).
  Future<void> playUrl(String url) async {
    try {
      await _effectPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint('AudioService: No se pudo reproducir URL $url — $e');
    }
  }

  Future<void> playBackgroundMusic(String path) async {
    try {
      await _bgPlayer.setReleaseMode(ReleaseMode.loop);
      await _bgPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint('AudioService: No se pudo reproducir música $path — $e');
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _bgPlayer.stop();
    } catch (e) {
      debugPrint('AudioService: Error al detener música — $e');
    }
  }

  void playSuccess() => playEffect('audio/success.wav');
  void playError() => playEffect('audio/error.wav');
  void playClick() => playEffect('audio/click.wav');
}

