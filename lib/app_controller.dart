import 'package:flutter/foundation.dart';

import 'models/chat_message.dart';
import 'models/local_post.dart';
import 'services/local_store.dart';

class AppController extends ChangeNotifier {
  final LocalStore _store = LocalStore();

  static const _userKey = 'onespase_user_name';
  static const _handleKey = 'onespase_user_handle';
  static const _bioKey = 'onespase_user_bio';
  static const _statusKey = 'onespase_user_status';
  static const _joinedKey = 'onespase_joined_at';
  static const _postsKey = 'onespase_posts';
  static const _messagesKey = 'onespase_messages';

  String? userName;
  String? userHandle;
  String bio = 'Моё пространство в OneSpase 🚀';
  String status = 'В сети';
  DateTime? joinedAt;

  final List<LocalPost> posts = [];
  final Map<String, List<ChatMessage>> chats = {};

  final Map<String, String> chatTitles = const {
    'alex': 'Алекс',
    'dev': 'Разработка OneSpase',
    'team': 'Команда',
  };

  Future<void> load() async {
    userName = await _store.getString(_userKey);
    userHandle = await _store.getString(_handleKey);
    bio = await _store.getString(_bioKey) ?? bio;
    status = await _store.getString(_statusKey) ?? status;
    final joinedRaw = await _store.getString(_joinedKey);
    joinedAt = joinedRaw == null ? null : DateTime.tryParse(joinedRaw);

    final storedPosts = await _store.getJsonList(_postsKey);
    if (storedPosts == null) {
      posts.addAll(_defaultPosts());
      await _savePosts();
    } else {
      posts.addAll(
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

    notifyListeners();
  }

  Future<void> enter(String name, String handle) async {
    final cleanedName = name.trim();
    var cleanedHandle = handle.trim().replaceAll('@', '').replaceAll(' ', '');
    if (cleanedName.isEmpty || cleanedHandle.isEmpty) return;

    userName = cleanedName;
    userHandle = cleanedHandle.toLowerCase();
    joinedAt ??= DateTime.now();

    await _store.setString(_userKey, userName!);
    await _store.setString(_handleKey, userHandle!);
    await _store.setString(_joinedKey, joinedAt!.toIso8601String());
    notifyListeners();
  }

  Future<void> logout() async {
    userName = null;
    userHandle = null;
    joinedAt = null;
    await _store.remove(_userKey);
    await _store.remove(_handleKey);
    await _store.remove(_joinedKey);
    notifyListeners();
  }

  Future<void> updateBio(String value) async {
    bio = value.trim();
    await _store.setString(_bioKey, bio);
    notifyListeners();
  }

  Future<void> updateStatus(String value) async {
    status = value.trim().isEmpty ? 'В сети' : value.trim();
    await _store.setString(_statusKey, status);
    notifyListeners();
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
          text: 'Добро пожаловать в OneSpase 🚀 Первый прототип уже умеет хранить локальные посты, лайки и сообщения.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
          likes: 7,
        ),
        LocalPost(
          id: 'dev_post',
          author: 'Разработка OneSpase',
          text: 'Следующий большой этап — настоящие аккаунты, серверная лента и сообщения между разными телефонами.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 4,
        ),
      ];

  Map<String, List<ChatMessage>> _defaultChats() => {
        'alex': [
          ChatMessage(
            id: 'a1',
            text: 'Йо! Как тебе OneSpase?',
            sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
            fromMe: false,
          ),
        ],
        'dev': [
          ChatMessage(
            id: 'd1',
            text: 'Тут будем обсуждать новые функции 🚀',
            sentAt: DateTime.now().subtract(const Duration(hours: 1)),
            fromMe: false,
          ),
        ],
        'team': [
          ChatMessage(
            id: 't1',
            text: 'Командный чат уже в прототипе.',
            sentAt: DateTime.now().subtract(const Duration(hours: 3)),
            fromMe: false,
          ),
        ],
      };
}
