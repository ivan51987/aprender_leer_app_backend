import 'package:shared_preferences/shared_preferences.dart';

class ProgressService {
  static const String _levelKey = 'current_level';
  static const String _starsKey = 'total_stars';
  static const String _ninoIdKey = 'nino_id';
  static const String _ninoNombreKey = 'nino_nombre';

  Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_ninoIdKey);
  }

  Future<void> registerNino(int id, String nombre) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_ninoIdKey, id);
    await prefs.setString(_ninoNombreKey, nombre);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_ninoIdKey);
    await prefs.remove(_ninoNombreKey);
    await prefs.remove(_levelKey);
    await prefs.remove(_starsKey);
  }

  Future<int?> getNinoId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_ninoIdKey);
  }

  Future<String?> getNinoNombre() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ninoNombreKey);
  }

  Future<int> getLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_levelKey) ?? 0;
  }

  Future<void> incrementLevel() async {
    final prefs = await SharedPreferences.getInstance();
    int current = await getLevel();
    await prefs.setInt(_levelKey, current + 1);
  }

  Future<int> getStars() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_starsKey) ?? 0;
  }

  Future<void> addStars(int amount) async {
    final prefs = await SharedPreferences.getInstance();
    int current = await getStars();
    await prefs.setInt(_starsKey, current + amount);
  }
}
