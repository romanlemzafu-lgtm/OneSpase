import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/social_profile.dart';

class SupabaseService {
  SupabaseService({required this.enabled});

  final bool enabled;

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => enabled ? _client.auth.currentUser : null;
  Session? get currentSession => enabled ? _client.auth.currentSession : null;

  Future<void> sendEmailOtp(String email) async {
    if (!enabled) throw StateError('Supabase не подключён к этой сборке.');
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  Future<User?> verifyEmailOtp(String email, String token) async {
    if (!enabled) throw StateError('Supabase не подключён к этой сборке.');
    final result = await _client.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: token,
    );
    return result.user;
  }

  Future<SocialProfile?> loadMyProfile() async {
    final user = currentUser;
    if (!enabled || user == null) return null;

    final row = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (row == null) return null;
    return SocialProfile.fromJson(Map<String, dynamic>.from(row));
  }

  Future<void> saveMyProfile({
    required String displayName,
    required String username,
    required String status,
    required String bio,
  }) async {
    final user = currentUser;
    if (!enabled || user == null) {
      throw StateError('Нет активной сессии OneSpase.');
    }

    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'display_name': displayName,
      'username': username.toLowerCase(),
      'status': status,
      'bio': bio,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<SocialProfile>> searchProfiles(String query) async {
    if (!enabled) return const [];
    final cleaned = query.trim().replaceAll('@', '');
    if (cleaned.isEmpty) return const [];

    final rows = await _client
        .from('profiles')
        .select('id, display_name, username, status, bio, avatar_url, online')
        .or('username.ilike.%$cleaned%,display_name.ilike.%$cleaned%')
        .limit(20);

    return (rows as List<dynamic>)
        .map((row) => SocialProfile.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .where((profile) => profile.id != currentUser?.id)
        .toList();
  }

  Future<void> signOut() async {
    if (enabled) await _client.auth.signOut();
  }
}
