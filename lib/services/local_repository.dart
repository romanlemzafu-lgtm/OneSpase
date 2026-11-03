import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalRepository {
  static const _key = 'onespase_v07_state';

  Future<Map<String, dynamic>?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(data));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<int> approxBytes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_key) ?? '').length;
  }
}
