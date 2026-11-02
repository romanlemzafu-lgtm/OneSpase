import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models/account_slot.dart';
import 'models/chat_message.dart';
import 'models/emoji_pack.dart';
import 'models/gift_item.dart';
import 'models/local_post.dart';
import 'models/remote_chat.dart';
import 'models/social_profile.dart';
import 'services/account_vault.dart';
import 'services/local_store.dart';
import 'services/supabase_service.dart';

enum AuthStep { choose, emailLogin, emailRegister, profile }

class AppController extends ChangeNotifier {
  AppController({required this.supabase});

  final SupabaseService supabase;
  final LocalStore _store = LocalStore();
  final AccountVault _vault = AccountVault();
  StreamSubscription<void>? _authSubscription;

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
  String verification = 'none';
  String profileTheme = 'purple';
  String emojiStatus = '';
  String musicTitle = '';
  String featuredChannel = '';
  DateTime? joinedAt;

  String? authError;
  bool authBusy = false;
  bool demoSession = false;
  bool isOwner = false;
  bool accountAuthMode = false;
  AuthStep authStep = AuthStep.choose;

  List<AccountSlot> accountSlots = const [];
  List<GiftItem> gifts = const [];
  List<EmojiPack> emojiPacks = const [];

  List<RemoteConversation> remoteConversations = const [];
  bool conversationsBusy = false;

  final List<LocalPost> posts = [];
  final Map<String, List<ChatMessage>> chats = {};

  final Map<String, String> chatTitles = const {
    'alex': 'Алекс',
    'dev': 'OneSpase Dev',
    'team': 'Команда',
  };

  bool get onlineConfigured => supabase.enabled;
  String? get currentUserId => supabase.currentUserId;
  bool get isOnlineAccount =>
      supabase.enabled && supabase.currentSession != null && !demoSession;
  bool get isSignedIn => !accountAuthMode && (demoSession || (isOnlineAccount && userName != null));

  final List<SocialProfile> demoPeople = const [
    SocialProfile(
      id: 'demo_1',
      displayName: 'Алекс',
      username: 'alex_space',
      status: 'Слушаю музыку',
      bio: 'Тут будет профиль настоящего пользователя.',
      online: true,
      verification: 'blue',
    ),
    SocialProfile(
      id: 'demo_2',
      displayName: 'Мира',
      username: 'mira',
      status: 'Работаю',
      bio: 'OneSpase beta',
      online: false,
      verification: 'purple',
    ),
    SocialProfile(
      id: 'demo_3',
      displayName: 'OneSpase Dev',
      username: 'onespase',
      status: 'Строим новое пространство 🚀',
      bio: 'Официальный профиль разработки.',
      online: true,
      verification: 'red',
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
    accountSlots = await _vault.loadSlots();

    if (supabase.enabled) {
      _authSubscription ??= supabase.authSessionChanges.listen(
        (_) async => _handleOnlineSession(),
        onError: (Object error, StackTrace stackTrace) {
          authError = _friendlyError(error);
          notifyListeners();
        },
      );
      await _handleOnlineSession();
    }

    notifyListeners();
  }

  Future<void> _handleOnlineSession() async {
    if (!supabase.enabled || supabase.currentSession == null) {
      if (!demoSession) {
        userName = null;
        userHandle = null;
        verification = 'none';
        isOwner = false;
        authStep = AuthStep.choose;
      }
      notifyListeners();
      return;
    }

    try {
      final profile = await supabase.loadMyProfile();
      if (profile == null ||
          profile.displayName == 'Новый пользователь' ||
          profile.username.startsWith('user_')) {
        demoSession = false;
        authStep = AuthStep.profile;
        userName = null;
        userHandle = null;
      } else {
        await _applyProfile(profile);
        await supabase.setPresence(true);
        await refreshConversations();
        await refreshExtras();
        await _saveCurrentAccountSlot();
      }
      isOwner = await supabase.isOwner();
      accountAuthMode = false;
    } catch (error) {
      authError = _friendlyError(error);
    }
    notifyListeners();
  }

  Future<void> startGuest() async {
    if (!supabase.enabled) {
      authError = 'Сначала подключи Supabase к APK.';
      notifyListeners();
      return;
    }

    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      await supabase.signInAnonymously();
      demoSession = false;
      authStep = AuthStep.profile;
    } catch (error) {
      authError = _friendlyError(error);
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  void showEmailLogin() {
    authError = null;
    authStep = AuthStep.emailLogin;
    notifyListeners();
  }

  void showEmailRegister() {
    authError = null;
    authStep = AuthStep.emailRegister;
    notifyListeners();
  }

  void showAuthChoice() {
    authError = null;
    authStep = AuthStep.choose;
    notifyListeners();
  }

  Future<void> registerWithEmail({
    required String email,
    required String password,
  }) async {
    if (!supabase.enabled) {
      authError = 'Сначала подключи Supabase к APK.';
      notifyListeners();
      return;
    }
    if (!email.contains('@') || password.length < 8) {
      authError = 'Нужна настоящая почта и пароль минимум из 8 символов.';
      notifyListeners();
      return;
    }

    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      await supabase.signUpWithEmail(email: email, password: password);
      if (supabase.currentSession == null) {
        authError = 'Аккаунт создан. В Supabase включено подтверждение email — либо подтверди письмо, либо отключи Confirm email.';
        authStep = AuthStep.emailLogin;
      } else {
        demoSession = false;
        authStep = AuthStep.profile;
      }
    } catch (error) {
      authError = _friendlyError(error);
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (!supabase.enabled) {
      authError = 'Сначала подключи Supabase к APK.';
      notifyListeners();
      return;
    }
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      await supabase.signInWithEmail(email: email, password: password);
      demoSession = false;
      await _handleOnlineSession();
    } catch (error) {
      authError = _friendlyError(error);
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<void> prepareAddAccount() async {
    await _saveCurrentAccountSlot();
    accountAuthMode = true;
    authStep = AuthStep.choose;
    authError = null;
    notifyListeners();
  }

  Future<void> cancelAddAccount() async {
    accountAuthMode = false;
    authError = null;
    notifyListeners();
  }

  Future<void> switchAccount(String userId) async {
    if (userId == currentUserId) {
      accountAuthMode = false;
      return;
    }
    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      await _saveCurrentAccountSlot();
      final token = await _vault.refreshTokenFor(userId);
      if (token == null || token.isEmpty) {
        throw StateError('Сессия этого аккаунта не сохранена. Войди в него заново.');
      }
      await supabase.restoreSession(token);
      await _handleOnlineSession();
    } catch (error) {
      authError = _friendlyError(error);
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<void> removeSavedAccount(String userId) async {
    if (userId == currentUserId) {
      await logout();
      return;
    }
    await _vault.removeAccount(userId);
    accountSlots = await _vault.loadSlots();
    notifyListeners();
  }

  Future<void> startGoogle() async {
    if (!supabase.enabled) {
      authError = 'Сначала подключи Supabase к APK.';
      notifyListeners();
      return;
    }

    authBusy = true;
    authError = null;
    notifyListeners();
    try {
      await supabase.signInWithGoogle();
    } catch (error) {
      authError = _friendlyError(error);
    } finally {
      authBusy = false;
      notifyListeners();
    }
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
      if (isOnlineAccount) {
        await supabase.saveMyProfile(
          displayName: cleanedName,
          username: cleanedHandle,
          status: newStatus.trim().isEmpty ? 'В OneSpase' : newStatus.trim(),
          bio: bio,
          profileTheme: profileTheme,
          emojiStatus: emojiStatus,
          musicTitle: musicTitle,
          featuredChannel: featuredChannel,
        );
      }

      userName = cleanedName;
      userHandle = cleanedHandle;
      status = newStatus.trim().isEmpty ? 'В OneSpase' : newStatus.trim();
      joinedAt ??= DateTime.now();
      demoSession = !isOnlineAccount;
      await _saveProfileLocally();

      if (isOnlineAccount) {
        final profile = await supabase.loadMyProfile();
        if (profile != null) await _applyProfile(profile);
        isOwner = await supabase.isOwner();
      accountAuthMode = false;
      }
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
    verification = 'purple';
    await _store.setString(_demoKey, 'true');
    await _saveProfileLocally();
    notifyListeners();
  }

  Future<void> logout() async {
    final leavingUserId = currentUserId;
    await supabase.signOut();
    if (leavingUserId != null) await _vault.removeAccount(leavingUserId);
    accountSlots = await _vault.loadSlots();
    demoSession = false;
    accountAuthMode = false;
    userName = null;
    userHandle = null;
    joinedAt = null;
    verification = 'none';
    isOwner = false;
    remoteConversations = const [];
    authStep = AuthStep.choose;
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

  Future<void> updateProfileCustomization({
    required String theme,
    required String newEmojiStatus,
    required String newMusicTitle,
    required String newFeaturedChannel,
  }) async {
    profileTheme = theme;
    emojiStatus = newEmojiStatus.trim();
    musicTitle = newMusicTitle.trim();
    featuredChannel = newFeaturedChannel.trim();
    await _syncProfileIfOnline();
    notifyListeners();
  }

  Future<void> refreshExtras() async {
    if (!isOnlineAccount) return;
    try {
      gifts = await supabase.myGifts();
    } catch (_) {
      gifts = const [];
    }
    try {
      emojiPacks = await supabase.myEmojiPacks();
    } catch (_) {
      emojiPacks = const [];
    }
    notifyListeners();
  }

  Future<List<GiftItem>> loadGiftCatalog() async {
    if (!isOnlineAccount) return const [];
    return supabase.giftCatalog();
  }

  Future<void> sendGift({
    required SocialProfile profile,
    required GiftItem gift,
    String? note,
  }) async {
    await supabase.sendGift(
      targetUserId: profile.id,
      giftSlug: gift.slug,
      note: note,
    );
  }

  Future<void> createEmojiPack({
    required String title,
    required String slug,
    required List<String> emojis,
  }) async {
    await supabase.createEmojiPack(
      title: title,
      slug: slug,
      emojis: emojis,
    );
    emojiPacks = await supabase.myEmojiPacks();
    notifyListeners();
  }

  Future<void> setPresence(bool online) async {
    if (!isOnlineAccount) return;
    try {
      await supabase.setPresence(online);
    } catch (_) {}
  }

  Future<List<SocialProfile>> searchPeople(
    String query, {
    bool includeSelf = false,
  }) async {
    final clean = query.trim().toLowerCase().replaceAll('@', '');

    if (isOnlineAccount) {
      try {
        return await supabase.searchProfiles(clean, includeSelf: includeSelf);
      } catch (error) {
        authError = _friendlyError(error);
      }
    }

    if (clean.isEmpty) return demoPeople;
    return demoPeople.where((profile) {
      return profile.displayName.toLowerCase().contains(clean) ||
          profile.username.toLowerCase().contains(clean);
    }).toList();
  }

  Future<String?> startDirectChat(SocialProfile profile) async {
    if (!isOnlineAccount) return null;
    try {
      final id = await supabase.startDirectConversation(profile.id);
      await refreshConversations();
      return id;
    } catch (error) {
      authError = _friendlyError(error);
      notifyListeners();
      return null;
    }
  }

  Future<void> refreshConversations() async {
    if (!isOnlineAccount) return;
    conversationsBusy = true;
    notifyListeners();
    try {
      remoteConversations = await supabase.listConversations();
    } catch (error) {
      authError = _friendlyError(error);
    } finally {
      conversationsBusy = false;
      notifyListeners();
    }
  }

  Stream<List<RemoteMessage>> remoteMessageStream(String conversationId) {
    return supabase.streamMessages(conversationId);
  }

  Future<void> sendRemoteMessage(String conversationId, String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await supabase.sendMessage(conversationId, clean);
  }

  Future<void> editRemoteMessage(String messageId, String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;
    await supabase.editMessage(messageId, clean);
  }

  Future<void> deleteRemoteMessage(String messageId) async {
    await supabase.deleteMessage(messageId);
  }

  Future<void> markConversationRead(String conversationId) async {
    try {
      await supabase.markConversationRead(conversationId);
    } catch (_) {}
  }

  Future<void> setVerificationBadge({
    required SocialProfile profile,
    required String badge,
    String? reason,
  }) async {
    if (!isOwner) throw StateError('Доступ только владельцу OneSpase.');
    await supabase.setVerificationBadge(
      targetUserId: profile.id,
      badge: badge,
      reason: reason,
    );
    if (profile.id == currentUserId) {
      verification = badge;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> loadBadgeAudit() {
    return supabase.badgeAudit();
  }

  Future<void> reserveUsername({
    required String username,
    SocialProfile? forProfile,
    String? reason,
  }) async {
    if (!isOwner) throw StateError('Доступ только владельцу OneSpase.');
    await supabase.reserveUsername(
      username: username.trim().replaceAll('@', '').toLowerCase(),
      targetUserId: forProfile?.id,
      reason: reason,
    );
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
    verification = profile.verification;
    profileTheme = profile.profileTheme;
    emojiStatus = profile.emojiStatus;
    musicTitle = profile.musicTitle;
    featuredChannel = profile.featuredChannel;
    joinedAt ??= DateTime.now();
    demoSession = false;
    await _store.remove(_demoKey);
    await _saveProfileLocally();
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
    if (!isOnlineAccount || userName == null || userHandle == null) return;
    try {
      await supabase.saveMyProfile(
        displayName: userName!,
        username: userHandle!,
        status: status,
        bio: bio,
        profileTheme: profileTheme,
        emojiStatus: emojiStatus,
        musicTitle: musicTitle,
        featuredChannel: featuredChannel,
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
    final low = text.toLowerCase();
    if (low.contains('anonymous') && low.contains('disabled')) {
      return 'В Supabase нужно включить Anonymous Sign-Ins.';
    }
    if (low.contains('provider') && low.contains('disabled')) {
      return 'Этот способ входа ещё не включён в Supabase.';
    }
    if (low.contains('rate')) {
      return 'Слишком много попыток. Попробуй чуть позже.';
    }
    if (low.contains('reserved username') || low.contains('protected username')) {
      return 'Этот @username зарезервирован. Для официальных названий нужно обратиться к владельцу OneSpase.';
    }
    if (low.contains('invalid login credentials')) {
      return 'Неверная почта или пароль.';
    }
    if (low.contains('user already registered')) {
      return 'Аккаунт с такой почтой уже существует.';
    }
    if (low.contains('duplicate') || low.contains('unique')) {
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
              'Добро пожаловать в OneSpase 🚀 v0.6 добавляет аккаунты, подарки, emoji-паки и оформление профиля.',
          createdAt: DateTime.now().subtract(const Duration(minutes: 18)),
          likes: 15,
          comments: ['Погнали!'],
        ),
        LocalPost(
          id: 'dev_post',
          author: 'OneSpase Dev',
          text:
              'Новая иконка, гостевой вход, Google OAuth, реальные личные сообщения и система галочек.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          likes: 11,
        ),
      ];

  Map<String, List<ChatMessage>> _defaultChats() => {
        'alex': [
          ChatMessage(
            id: 'a1',
            text: 'Йо! Это демо-чат. Онлайн-чаты появятся после подключения Supabase.',
            sentAt: DateTime.now().subtract(const Duration(minutes: 12)),
            fromMe: false,
          ),
        ],
        'dev': [
          ChatMessage(
            id: 'd1',
            text: 'v0.6 уже тут 🚀',
            sentAt: DateTime.now().subtract(const Duration(hours: 1)),
            fromMe: false,
          ),
        ],
        'team': [
          ChatMessage(
            id: 't1',
            text: 'Owner Panel и галочки защищены на стороне базы.',
            sentAt: DateTime.now().subtract(const Duration(hours: 3)),
            fromMe: false,
          ),
        ],
      };

  Future<void> _saveCurrentAccountSlot() async {
    final session = supabase.currentSession;
    final profileName = userName;
    final profileHandle = userHandle;
    if (!isOnlineAccount ||
        session == null ||
        profileName == null ||
        profileHandle == null) {
      return;
    }
    await _vault.saveAccount(
      slot: AccountSlot(
        userId: session.user.id,
        label: profileName,
        username: profileHandle,
        email: session.user.email,
      ),
      refreshToken: session.refreshToken,
    );
    accountSlots = await _vault.loadSlots();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
