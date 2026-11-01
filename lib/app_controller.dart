import 'package:flutter/foundation.dart';

import 'models/chat_message.dart';
import 'models/local_post.dart';
import 'models/social_profile.dart';
import 'services/local_store.dart';
import 'services/supabase_service.dart';

enum AuthStep { email, otp, profile }

class AppController extends ChangeNotifier {
  AppController({required this.supabase});

  final SupabaseService supabase;
  final LocalStore _store = LocalStore();

  static const _userKey = 'onespase_user_name';
  static const _handleKey = 'onespase_user_handle';
  static const _bioKey = 'onespase_user_bio';
  static const _statusKey = 'onespase_user_status';
  static const _joinedKey = 'onespase_joined_at';
  static const _postsKey = 'onespase_posts';
  static const _messagesKey = 'onespase_messages';
  static const _demoKey = 'onespase_demo_session';

  String? userName;
  String? userHandle;
  String bio = 'Моё пространство в OneSpase 🚀';
  String status = 'В сети';
  DateTime? joinedAt;

  String pendingEmail = '';
  String? authError;
  bool authBusy = false;
  bool demoSession = false;
  AuthStep authStep = AuthStep.email;

  final List<LocalPost> posts = [];
  final Map<String, List<ChatMessage>> chats = {};

  final Map<String, String> chatTitles = const {
    'alex': 'Алекс',
    'dev': 'OneSpase Dev',
    'team': 'Команда',
  };

  bool get onlineConfigured => supabase.enabled;
  bool get isSignedIn =>
      demoSession || (supabase.currentSession != null && userName != null);

  final List<SocialProfile> demoPeople = const [
    SocialProfile(
      id: 'demo_1',
      displayName: 'Алекс',
      username: 'alex_space',
      status: 'Слушаю музыку',
      bio: 'Тут будет профиль настоящего пользователя.',
      online: true,
    ),
    SocialProfile(
      id: 'demo_2',
      displayName: 'Мира',
      username: 'mira',
      status: 'Работаю',
      bio: 'OneSpase beta',
      online: false,
    ),
    SocialProfile(
      id: 'demo_3',
      displayName: 'OneSpase Dev',
      username: 'onespase',
      status: 'Строим новое пространство 🚀',
      bio: 'Официальный профиль разработки.',
      online: true,
    ),
  ];

  Future<void> load() async {
    userName = await _store.getString(_userKey);
    userHandle = await _store.getString(_handleKey);
    bio = await _store.getString(_bioKey) ?? bio;
    status = await _store.getString(_statusKey) ?? status;
    final joinedRaw = await _store.getString(_joinedKey);
    joinedAt = joinedRaw == null ? null : DateTime.tryParse(joinedRaw);
    demoSession = await _store.getString(_demoKey) == 'true';

    await _loadLocalContent();

    if (supabase.enabled && supabase.currentSession != null) {
      final profile = await supabase.loadMyProfile();
      if (profile == null) {
        userName = null;
        userHandle = null;
        authStep = AuthStep.profile;
      } else {
        await _applyProfile(profile);
      }
    }

    notifyListeners();
  }

  Future<void> _loadLocalContent() async {
    final storedPosts = await _store.getJsonList(_postsKey);
    if (storedPosts == null) {
      posts.addAll(_defaultPosts());
      await _savePosts();
    } else {
      posts
        ..clear()
        ..addAll(
          storedPosts.map(
            (item) => LocalPost.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          ),
        );
    }

    final storedMessages = await _store.getJsonMap(_messagesKey);
    if (storedMessages == null) {
      chats.addAll(_defaultChats());
      await _saveChats();
    } else {
      chats.clear();
      for (final entry in storedMessages.entries) {
        final items = entry.value as List<dynamic>;
        chats[entry.key] = items
            .map(
              (item) => ChatMessage.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      }
    }
  }

  Future<void> requestEmailOtp(String email) async {
    final clean = email.trim().toLowerCase();
    if (!clean.contains('@') || !clean.contains('.')) {
      authError = 'Проверь адрес почты.';
      notifyListeners();
      return;
    }

    if (!supabase.enabled) {
      authError = 'Онлайн-сервер ещё не подключён к этой APK. Можно открыть демо.';
      notifyListeners();
      return;
    }

    authBusy = true;
    authError = null;
    notifyListeners();

    try {
      await supabase.sendEmailOtp(clean);
      pendingEmail = clean;
      authStep = AuthStep.otp;
    } catch (error) {
      authError = _friendlyError(error);
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<void> verifyOtp(String token) async {
    final clean = token.replaceAll(RegExp(r'\D'), '');
    if (clean.length < 6) {
      authError = 'Введи код из письма полностью.';
      notifyListeners();
      return;
    }

    authBusy = true;
    authError = null;
    notifyListeners();

    try {
      await supabase.verifyEmailOtp(pendingEmail, clean);
      final profile = await supabase.loadMyProfile();
      if (profile == null || profile.username.trim().isEmpty) {
        authStep = AuthStep.profile;
      } else {
        await _applyProfile(profile);
      }
    } catch (error) {
      authError = _friendlyError(error);
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<void> resendOtp() async {
    if (pendingEmail.isEmpty) return;
    await requestEmailOtp(pendingEmail);
  }

  void backToEmail() {
    authStep = AuthStep.email;
    authError = null;
    notifyListeners();
  }

  Future<void> completeProfile({
    required String name,
    required String handle,
    required String newStatus,
  }) async {
    final cleanedName = name.trim();
    final cleanedHandle = _cleanHandle(handle);
    if (cleanedName.length < 2) {
      authError = 'Имя слишком короткое.';
      notifyListeners();
      return;
    }
    if (cleanedHandle.length < 3) {
      authError = '@username должен быть минимум из 3 символов.';
      notifyListeners();
      return;
    }

    authBusy = true;
    authError = null;
    notifyListeners();

    try {
      if (supabase.enabled && supabase.currentSession != null) {
        await supabase.saveMyProfile(
          displayName: cleanedName,
          username: cleanedHandle,
          status: newStatus.trim().isEmpty ? 'В OneSpase' : newStatus.trim(),
          bio: bio,
        );
      }

      userName = cleanedName;
      userHandle = cleanedHandle;
      status = newStatus.trim().isEmpty ? 'В OneSpase' : newStatus.trim();
      joinedAt ??= DateTime.now();
      await _saveProfileLocally();
    } catch (error) {
      authError = _friendlyError(error);
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<void> startDemo() async {
    demoSession = true;
    userName ??= 'Рома';
    userHandle ??= 'roman';
    joinedAt ??= DateTime.now();
    await _store.setString(_demoKey, 'true');
    await _saveProfileLocally();
    notifyListeners();
  }

  Future<void> logout() async {
    await supabase.signOut();
    demoSession = false;
    userName = null;
    userHandle = null;
    joinedAt = null;
    authStep = AuthStep.email;
    pendingEmail = '';
    authError = null;
    await _store.remove(_demoKey);
    await _store.remove(_userKey);
    await _store.remove(_handleKey);
    await _store.remove(_joinedKey);
    notifyListeners();
  }

  Future<void> updateBio(String value) async {
    bio = value.trim();
    await _store.setString(_bioKey, bio);
    await _syncProfileIfOnline();
    notifyListeners();
  }

  Future<void> updateStatus(String value) async {
    status = value.trim().isEmpty ? 'В сети' : value.trim();
    await _store.setString(_statusKey, status);
    await _syncProfileIfOnline();
    notifyListeners();
  }

  Future<List<SocialProfile>> searchPeople(String query) async {
    final clean = query.trim().toLowerCase().replaceAll('@', '');
    if (clean.isEmpty) return demoPeople;

    if (supabase.enabled && supabase.currentSession != null) {
      try {
        return await supabase.searchProfiles(clean);
      } catch (_) {
        // Если сервер временно недоступен, интерфейс всё равно остаётся живым.
      }
    }

    return demoPeople.where((profile) {
      return profile.displayName.toLowerCase().contains(clean) ||
          profile.username.toLowerCase().contains(clean);
    }).toList();
  }

  Future<void> addPost(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty || userName == null) return;

    posts.insert(
      0,
      LocalPost(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        author: userName!,
        text: cleaned,
        createdAt: DateTime.now(),
      ),
    );
    await _savePosts();
    notifyListeners();
  }

  Future<void> toggleLike(LocalPost post) async {
    if (post.likedByMe) {
      post.likedByMe = false;
      if (post.likes > 0) post.likes--;
    } else {
      post.likedByMe = true;
      post.likes++;
    }
    await _savePosts();
    notifyListeners();
  }

  Future<void> addComment(LocalPost post, String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    post.comments.add(cleaned);
    await _savePosts();
    notifyListeners();
  }

  Future<void> sendMessage(String chatId, String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) return;
    final list = chats.putIfAbsent(chatId, () => []);
    list.add(
      ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: cleaned,
        sentAt: DateTime.now(),
        fromMe: true,
      ),
    );
    await _saveChats();
    notifyListeners();
  }

  String lastMessage(String chatId) {
    final list = chats[chatId] ?? const [];
    if (list.isEmpty) return 'Сообщений пока нет';
    return list.last.text;
  }

  Future<void> _applyProfile(SocialProfile profile) async {
    userName = profile.displayName;
    userHandle = profile.username;
    status = profile.status;
    bio = profile.bio.isEmpty ? bio : profile.bio;
    joinedAt ??= DateTime.now();
    demoSession = false;
    await _saveProfileLocally();
  }

  Future<void> _saveProfileLocally() async {
    if (userName != null) await _store.setString(_userKey, userName!);
    if (userHandle != null) await _store.setString(_handleKey, userHandle!);
    await _store.setString(_bioKey, bio);
    await _store.setString(_statusKey, status);
    if (joinedAt != null) {
      await _store.setString(_joinedKey, joinedAt!.toIso8601String());
    }
  }

  Future<void> _syncProfileIfOnline() async {
    if (!supabase.enabled || supabase.currentSession == null) return;
    if (userName == null || userHandle == null) return;
    try {
      await supabase.saveMyProfile(
        displayName: userName!,
        username: userHandle!,
        status: status,
        bio: bio,
      );
    } catch (_) {}
  }

  String _cleanHandle(String input) {
    return input
        .trim()
        .replaceAll('@', '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '')
        .toLowerCase();
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.toLowerCase().contains('rate')) {
      return 'Слишком много попыток. Попробуй чуть позже.';
    }
    if (text.toLowerCase().contains('duplicate') ||
        text.toLowerCase().contains('unique')) {
      return 'Такой @username уже занят.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  Future<void> _savePosts() => _store.setJson(
        _postsKey,
        posts.map((post) => post.toJson()).toList(),
      );

  Future<void> _saveChats() {
    final data = <String, dynamic>{};
    for (final entry in chats.entries) {
      data[entry.key] = entry.value.map((message) => message.toJson()).toList();
    }
    return _store.setJson(_messagesKey, data);
  }

  List<LocalPost> _defaultPosts() => [
        LocalPost(
          id: 'welcome',
          author: 'OneSpase',
          text:
              'Добро пожаловать в OneSpase 🚀 Лента, профили и чаты уже собираются в одну уютную соцсеть.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
          likes: 12,
          comments: ['Ждём онлайн-версию!'],
        ),
        LocalPost(
          id: 'dev_post',
          author: 'OneSpase Dev',
          text:
              'v0.4: почта + код, поиск людей, новая навигация и подготовка к настоящим чатам.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 8,
        ),
      ];

  Map<String, List<ChatMessage>> _defaultChats() => {
        'alex': [
          ChatMessage(
            id: 'a1',
            text: 'Йо! Новый стиль OneSpase реально уютный.',
            sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
            fromMe: false,
          ),
        ],
        'dev': [
          ChatMessage(
            id: 'd1',
            text: 'v0.4 уже в разработке 🚀',
            sentAt: DateTime.now().subtract(const Duration(hours: 1)),
            fromMe: false,
          ),
        ],
        'team': [
          ChatMessage(
            id: 't1',
            text: 'Следом — серверные сообщения и друзья.',
            sentAt: DateTime.now().subtract(const Duration(hours: 3)),
            fromMe: false,
          ),
        ],
      };
}
