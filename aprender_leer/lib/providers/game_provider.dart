import 'package:flutter/material.dart';
import '../models/api_models.dart';
import '../services/progress_service.dart';
import '../services/api_service.dart';

class GameProvider with ChangeNotifier {
  final ProgressService _progressService = ProgressService();

  int _currentLevel = 0;
  int _stars = 0;

  // Lesson / quiz state
  List<CategoryItem> currentItems = [];
  List<QuizQuestion> currentQuiz = [];
  bool isLoading = false;
  String? error;
  String? currentCategoryId;

  int get currentLevel => _currentLevel;
  int get stars => _stars;

  GameProvider() {
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    _currentLevel = await _progressService.getLevel();
    _stars = await _progressService.getStars();
    notifyListeners();
  }

  Future<void> completeLevel(int starsGained) async {
    await _progressService.incrementLevel();
    await _progressService.addStars(starsGained);
    await _loadProgress();
  }

  Future<void> loadLesson(String categoryId) async {
    isLoading = true;
    error = null;
    currentCategoryId = categoryId;
    notifyListeners();
    try {
      currentItems = await ApiService().getLesson(categoryId);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadQuiz(String categoryId) async {
    isLoading = true;
    error = null;
    currentCategoryId = categoryId;
    notifyListeners();
    try {
      currentQuiz = await ApiService().getQuiz(categoryId);
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
