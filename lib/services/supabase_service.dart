import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emoji_pack.dart';
import '../models/gift_item.dart';
import '../models/remote_chat.dart';
import '../models/social_profile.dart';

class SupabaseService {
  SupabaseService({required this.enabled});

  final bool enabled;

  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => enabled ? _client.auth.currentUser : null;
  Session? get currentSession => enabled ? _client.auth.currentSession : null;
  String? get currentUserId => currentUser?.id;
  String? get currentRefreshToken => currentSession?.refreshToken;
  Stream<void> get authSessionChanges =>
      _client.auth.onAuthStateChange.map<void>((_) {});

  Future<User?> signInAnonymously() async {
    if (!enabled) throw StateError('Supabase не подключён к этой сборке.');
    final result = await _client.auth.signInAnonymously();
    return result.user;
  }

  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
    String? username,
  }) async {
    if (!enabled) throw StateError('Supabase не подключён к этой сборке.');
    final result = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        if (displayName != null) 'display_name': displayName.trim(),
        if (username != null) 'username': username.trim().toLowerCase(),
      },
    );
    return result.user;
  }

  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!enabled) throw StateError('Supabase не подключён к этой сборке.');
    final result = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return result.user;
  }

  Future<void> restoreSession(String refreshToken) async {
    if (!enabled) throw StateError('Supabase не подключён к этой сборке.');
    await _client.auth.setSession(refreshToken);
  }

  Future<void> signInWithGoogle() async {
    if (!enabled) throw StateError('Supabase не подключён к этой сборке.');
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'onespase://login-callback',
    );
  }

  Future<SocialProfile?> loadMyProfile() async {
    final user = currentUser;
    if (!enabled || user == null) return null;

    final rows = await _client.rpc('get_profile_with_badge', params: {
      'target_user': user.id,
    });

    if (rows is List && rows.isNotEmpty) {
      return SocialProfile.fromJson(
        Map<String, dynamic>.from(rows.first as Map),
      );
    }
    return null;
  }

  Future<void> saveMyProfile({
    required String displayName,
    required String username,
    required String status,
    required String bio,
    String profileTheme = 'purple',
    String emojiStatus = '',
    String musicTitle = '',
    String featuredChannel = '',
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
      'profile_theme': profileTheme,
      'emoji_status': emojiStatus,
      'music_title': musicTitle,
      'featured_channel': featuredChannel,
      'online': true,
      'last_seen_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<SocialProfile>> searchProfiles(
    String query, {
    bool includeSelf = false,
  }) async {
    if (!enabled || currentUser == null) return const [];
    final cleaned = query.trim().replaceAll('@', '');
    final rows = await _client.rpc('search_people', params: {
      'search_text': cleaned,
      'include_self': includeSelf,
    });

    return (rows as List<dynamic>)
        .map((row) => SocialProfile.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .where((profile) => includeSelf || profile.id != currentUser?.id)
        .toList();
  }

  Future<String> startDirectConversation(String targetUserId) async {
    if (!enabled || currentUser == null) {
      throw StateError('Сначала войди в OneSpase.');
    }
    final result = await _client.rpc('start_direct_conversation', params: {
      'target_user': targetUserId,
    });
    return result.toString();
  }

  Future<List<RemoteConversation>> listConversations() async {
    if (!enabled || currentUser == null) return const [];
    final rows = await _client.rpc('list_my_conversations');
    return (rows as List<dynamic>)
        .map((row) => RemoteConversation.fromJson(
              Map<String, dynamic>.from(row as Map),
            ))
        .toList();
  }

  Stream<List<RemoteMessage>> streamMessages(String conversationId) {
    if (!enabled || currentUser == null) {
      return Stream.value(const <RemoteMessage>[]);
    }

    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map(
          (rows) => rows
              .map((row) => RemoteMessage.fromJson(row))
              .toList(growable: false),
        );
  }

  Future<void> sendMessage(String conversationId, String body) async {
    final user = currentUser;
    if (!enabled || user == null) throw StateError('Нет активной сессии.');
    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': user.id,
      'body': body,
    });
  }

  Future<void> editMessage(String messageId, String body) async {
    final user = currentUser;
    if (!enabled || user == null) return;
    await _client.from('messages').update({
      'body': body,
      'edited_at': DateTime.now().toIso8601String(),
    }).eq('id', messageId).eq('sender_id', user.id);
  }

  Future<void> deleteMessage(String messageId) async {
    final user = currentUser;
    if (!enabled || user == null) return;
    await _client
        .from('messages')
        .delete()
        .eq('id', messageId)
        .eq('sender_id', user.id);
  }

  Future<void> markConversationRead(String conversationId) async {
    if (!enabled || currentUser == null) return;
    await _client.rpc('mark_conversation_read', params: {
      'target_conversation': conversationId,
    });
  }

  Future<void> setPresence(bool online) async {
    final user = currentUser;
    if (!enabled || user == null) return;
    await _client.from('profiles').update({
      'online': online,
      'last_seen_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);
  }

  Future<List<GiftItem>> giftCatalog() async {
    if (!enabled || currentUser == null) return const [];
    final rows = await _client
        .from('gift_catalog')
        .select()
        .eq('enabled', true)
        .order('sort_order');
    return (rows as List<dynamic>)
        .map((row) => GiftItem.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<List<GiftItem>> myGifts() async {
    if (!enabled || currentUser == null) return const [];
    final rows = await _client.rpc('list_my_gifts');
    return (rows as List<dynamic>)
        .map((row) => GiftItem.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<void> sendGift({
    required String targetUserId,
    required String giftSlug,
    String? note,
  }) async {
    if (!enabled || currentUser == null) throw StateError('Нет сессии.');
    await _client.rpc('send_free_gift', params: {
      'target_user': targetUserId,
      'gift_slug': giftSlug,
      'gift_note': note,
    });
  }

  Future<List<EmojiPack>> myEmojiPacks() async {
    if (!enabled || currentUser == null) return const [];
    final rows = await _client.rpc('list_my_emoji_packs');
    return (rows as List<dynamic>)
        .map((row) => EmojiPack.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(growable: false);
  }

  Future<void> createEmojiPack({
    required String title,
    required String slug,
    required List<String> emojis,
  }) async {
    if (!enabled || currentUser == null) throw StateError('Нет сессии.');
    await _client.rpc('create_emoji_pack', params: {
      'pack_title': title,
      'pack_slug': slug,
      'pack_emojis': emojis,
    });
  }

  Future<bool> isOwner() async {
    if (!enabled || currentUser == null) return false;
    final result = await _client.rpc('is_owner');
    return result == true;
  }

  Future<void> setVerificationBadge({
    required String targetUserId,
    required String badge,
    String? reason,
  }) async {
    if (!enabled || currentUser == null) {
      throw StateError('Нет активной сессии.');
    }
    await _client.rpc('set_verification_badge', params: {
      'target_user': targetUserId,
      'new_badge': badge,
      'badge_reason': reason,
    });
  }

  Future<List<Map<String, dynamic>>> badgeAudit() async {
    if (!enabled || currentUser == null) return const [];
    final rows = await _client.rpc('list_badge_audit');
    return (rows as List<dynamic>)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<void> reserveUsername({
    required String username,
    String? targetUserId,
    String? reason,
  }) async {
    if (!enabled || currentUser == null) throw StateError('Нет активной сессии.');
    await _client.rpc('reserve_username', params: {
      'target_username': username,
      'target_user': targetUserId,
      'reserve_reason': reason,
    });
  }

  Future<void> signOut() async {
    if (enabled) {
      await setPresence(false);
      await _client.auth.signOut(scope: SignOutScope.local);
    }
  }
}
