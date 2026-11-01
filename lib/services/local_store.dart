import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class LocalStore {
  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<String?> getString(String key) => _prefs.getString(key);

  Future<void> setString(String key, String value) =>
      _prefs.setString(key, value);

  Future<void> remove(String key) => _prefs.remove(key);

  Future<Map<String, dynamic>?> getJsonMap(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<List<dynamic>?> getJsonList(String key) async {
    final raw = await getString(key);
    if (raw == null || raw.isEmpty) return null;
    return jsonDecode(raw) as List<dynamic>;
  }

  Future<void> setJson(String key, Object value) =>
      setString(key, jsonEncode(value));
}
