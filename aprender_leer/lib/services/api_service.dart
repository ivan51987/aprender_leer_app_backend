import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/api_models.dart' as models;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  /// Base URL de la API
  String get baseUrl {
    const String envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // --- CONFIGURACIÓN DE IP ---
    // Cambia aquí según tu necesidad:
    // 1. VPN: '82.39.109.74'
    // 2. Local PC: '192.168.0.2'
    // 3. Emulador viendo a PC: '10.0.2.2'
    const String targetIp = '192.168.0.2'; 
    const String port = '4001';
    
    return 'http://$targetIp:$port';
  }

  /// Verifica si el servidor es alcanzable
  Future<bool> checkHealth() async {
    final uri = Uri.parse('$baseUrl/api/health');
    print('Mobile: Verificando salud del servidor en $uri...');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        print('Mobile: Salud OK: ${response.body}');
        return true;
      }
      print('Mobile: Salud fallida con status: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Mobile: Error en Health Check a $uri: $e');
      return false;
    }
  }

  Future<T> _get<T>(String path, T Function(dynamic json) parse) async {
    final uri = Uri.parse('$baseUrl$path');
    print('Mobile: GET Request a: $uri');
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return parse(json);
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } on SocketException catch (e) {
      print('Mobile: SocketException al conectar a $uri: $e');
      throw Exception('No se pudo conectar al servidor ($uri). Revisa Firewall/VPN/Wi-Fi.');
    } catch (e) {
      print('Mobile: Error de red inesperado en $uri: $e');
      throw Exception('Error de red: $e');
    }
  }

  /// Register a new child via backend API
  Future<Map<String, dynamic>> registerNino(String nombre) async {
    final uri = Uri.parse('$baseUrl/api/ninos');
    print('Mobile: Intentando registrar niño: $nombre en $uri');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'nombre': nombre}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        print('Mobile: Registro exitoso. Respuesta: ${response.body}');
        return jsonDecode(response.body);
      } else {
        print('Mobile: Error en respuesta de registro. Status: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Error registrando niño: ${response.statusCode}');
      }
    } catch (e) {
      print('Mobile: Error de red durante el registro: $e');
      throw Exception('Network error during registration: $e');
    }
  }

  /// Save game score via backend API
  Future<void> saveScore({
    required int ninoId,
    required String category,
    String? gameType,
    required int score,
    int stars = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/api/scores');
    try {
      final body = jsonEncode({
        'nino_id': ninoId,
        'categoria': category,
        'juego_tipo': gameType,
        'puntuacion': score,
        'estrellas': stars,
      });
      print('Mobile: Enviando puntuación al API: $body');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      ).timeout(const Duration(seconds: 10));

      print('Mobile: Respuesta de saveScore: Status ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode != 200) {
        print('Error saving score: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Network error saving score: $e');
    }
  }

  /// Returns all categories from /api/categories
  Future<List<models.Category>> getCategories() {
    return _get('/api/categories', (json) {
      final list = json['categories'] as List<dynamic>? ?? [];
      return list.map((e) => models.Category.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Returns lesson items for a category from /api/game/lesson/:categoryId
  Future<List<models.CategoryItem>> getLesson(String categoryId) {
    return _get('/api/game/lesson/$categoryId', (json) {
      final list = json['items'] as List<dynamic>? ?? [];
      return list.map((e) => models.CategoryItem.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Returns 5 quiz questions from /api/game/quiz/:categoryId
  Future<List<models.QuizQuestion>> getQuiz(String categoryId) {
    return _get('/api/game/quiz/$categoryId', (json) {
      final list = json['questions'] as List<dynamic>? ?? [];
      return list.map((e) => models.QuizQuestion.fromJson(e as Map<String, dynamic>)).toList();
    });
  }

  /// Get statistics for a child (level, gems, streak)
  Future<Map<String, dynamic>> getNinoStats(int ninoId) async {
    return _get('/api/ninos/$ninoId/stats', (json) => json as Map<String, dynamic>);
  }

  /// Get mastered words for a child
  Future<List<dynamic>> getMasteredWords(int ninoId) async {
    return _get('/api/ninos/$ninoId/mastered-words', (json) => json['mastered'] as List<dynamic>);
  }

  /// Mark an item as learned and get gems
  Future<Map<String, dynamic>> learnItem(int ninoId, String category, String item) async {
    final uri = Uri.parse('$baseUrl/api/ninos/$ninoId/learn');
    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'category': category, 'item': item}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Error learning item: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error learning item: $e');
    }
  }

  /// Get leaderboard top 5
  Future<List<dynamic>> getLeaderboard() async {
    return _get('/api/leaderboard', (json) => json as List<dynamic>);
  }

  /// Get rank for a child
  Future<int?> getNinoRank(int ninoId) async {
    return _get('/api/ninos/$ninoId/rank', (json) => json['rank'] as int?);
  }
}
