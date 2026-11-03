import 'package:flutter/foundation.dart';
import 'models/models.dart';
import 'services/local_repository.dart';

class AppController extends ChangeNotifier {
  AppController(this.repo);
  final LocalRepository repo;

  final List<UserProfile> users = [];
  final List<AccountProfile> accounts = [];
  final List<ChatThread> chats = [];
  final List<PostItem> posts = [];
  final List<GiftInstance> gifts = [];
  final List<EmojiPack> emojiPacks = [];
  final List<StoryItem> stories = [];
  final Set<String> reservedUsernames = {
    'onespase','roma','kotost','mzdiff','telegram','vk','discord','instagram','youtube','whatsapp','tiktok','facebook','signal'
  };
  AppSettings settings = AppSettings();
  String currentAccountId = '';
  int cacheBytes = 0;

  String _id() => DateTime.now().microsecondsSinceEpoch.toString();

  UserProfile get me {
    final account = accounts.firstWhere((a) => a.id == currentAccountId, orElse: () => accounts.first);
    return users.firstWhere((u) => u.id == account.userId);
  }

  List<GiftInstance> get myGifts => gifts.where((g) => g.receiverId == me.id && !g.hidden).toList()
    ..sort((a,b) => (b.pinned ? 1 : 0).compareTo(a.pinned ? 1 : 0));
  List<PostItem> get myPosts => posts.where((p) => p.authorId == me.id).toList();
  bool get isPlus => me.plus;
  int get maxAccounts => isPlus ? 5 : 2;
  int get maxEmojiPacks => isPlus ? 20 : 3;
  int get maxStories => isPlus ? 20 : 3;
  List<String> get availableReactions => isPlus
      ? const ['💜','👍','😂','🔥','🤯','👑','🚀','✨']
      : const ['💜','👍','😂'];

  List<StoryItem> get liveStories {
    final list = stories.where((s) => !s.expired).toList();
    list.sort((a,b) {
      final ap = userById(a.authorId).plus ? 1 : 0;
      final bp = userById(b.authorId).plus ? 1 : 0;
      return bp.compareTo(ap);
    });
    return list;
  }

  Future<void> load() async {
    final data = await repo.load();
    if (data == null) {
      _seed();
      await save();
    } else {
      _fromJson(data);
    }
    cacheBytes = await repo.approxBytes();
    notifyListeners();
  }

  void _seed() {
    users
      ..clear()
      ..addAll([
        UserProfile(id:'u_roma', name:'Рома', username:'roma', verification:'red', emojiStatus:'🚀', status:'Делаю OneSpase', music:'Night Drive', channel:'mzdiff', theme:'purple'),
        UserProfile(id:'u_mira', name:'Мира', username:'mira', verification:'purple', emojiStatus:'✨', status:'Работаю', bio:'Менеджер проекта OneSpase', music:'Lo-fi evening', theme:'mint'),
        UserProfile(id:'u_alex', name:'Алекс', username:'alex_space', verification:'blue', status:'В сети', bio:'Игры, мемы и немного хаоса', theme:'blue'),
        UserProfile(id:'u_dev', name:'OneSpase', username:'onespase', verification:'red', emojiStatus:'🛰️', status:'Официальный аккаунт', bio:'Строим новое пространство.', theme:'purple', plus:true),
      ]);
    accounts
      ..clear()
      ..addAll([
        AccountProfile(id:'acc_main', userId:'u_roma', label:'Основной'),
        AccountProfile(id:'acc_mira', userId:'u_mira', label:'Второй аккаунт'),
      ]);
    currentAccountId = 'acc_main';

    chats
      ..clear()
      ..addAll([
        ChatThread(id:'saved', title:'Избранное', kind:'saved', peerId:'u_roma', messages:[
          ChatMessage(id:'m1', senderId:'u_roma', text:'Сюда можно сохранять заметки и важные сообщения.', sentAt:DateTime.now().subtract(const Duration(hours:3))),
        ])..pinned = true,
        ChatThread(id:'chat_mira', title:'Мира', kind:'personal', peerId:'u_mira', messages:[
          ChatMessage(id:'m2', senderId:'u_mira', text:'Я проверила новую версию, выглядит уютно 👀', sentAt:DateTime.now().subtract(const Duration(minutes:40))),
          ChatMessage(id:'m3', senderId:'u_roma', text:'Ща ещё подарки добавим', sentAt:DateTime.now().subtract(const Duration(minutes:35))),
        ]),
        ChatThread(id:'group_dev', title:'OneSpase Dev', kind:'group', peerId:'u_dev', messages:[
          ChatMessage(id:'m4', senderId:'u_dev', text:'v0.7 теперь работает локально без Supabase.', sentAt:DateTime.now().subtract(const Duration(minutes:10))),
        ]),
        ChatThread(id:'channel_news', title:'OneSpase News', kind:'channel', peerId:'u_dev', messages:[
          ChatMessage(id:'m5', senderId:'u_dev', text:'Первый подарок — «Секретный пакетик».', sentAt:DateTime.now().subtract(const Duration(minutes:5))),
        ]),
      ]);

    posts
      ..clear()
      ..addAll([
        PostItem(id:'p1', authorId:'u_dev', text:'OneSpase v0.7: делаем приложение полностью кликабельным даже без сервера 🚀', createdAt:DateTime.now().subtract(const Duration(hours:2)), likes:27, comments:4),
        PostItem(id:'p2', authorId:'u_mira', text:'Тёмная тема + большие карточки = оставляем.', createdAt:DateTime.now().subtract(const Duration(hours:1)), likes:13, comments:2),
      ]);

    gifts
      ..clear()
      ..add(GiftInstance(id:'g1', slug:'secret_packet', senderId:'u_dev', receiverId:'u_roma', serial:1, sentAt:DateTime.now().subtract(const Duration(days:1)), note:'Первый официальный подарок OneSpase', pinned:true));

    emojiPacks
      ..clear()
      ..add(EmojiPack(id:'e1', title:'Kotost', slug:'kotost', items:['🐱','😭','💜','🚀']));

    stories
      ..clear()
      ..addAll([
        StoryItem(id:'s1', authorId:'u_mira', text:'Новая версия уже на подходе ✨', createdAt:DateTime.now().subtract(const Duration(hours:2))),
        StoryItem(id:'s2', authorId:'u_dev', text:'OneSpase Offline Prototype', createdAt:DateTime.now().subtract(const Duration(hours:4)), pinned:true),
      ]);
    settings = AppSettings();
  }

  UserProfile userById(String id) => users.firstWhere((u) => u.id == id, orElse: () => me);
  ChatThread chatById(String id) => chats.firstWhere((c) => c.id == id);

  Future<void> save() async {
    await repo.save(_toJson());
    cacheBytes = await repo.approxBytes();
    notifyListeners();
  }

  Map<String,dynamic> _toJson() => {
    'users': users.map((e)=>e.toJson()).toList(),
    'accounts': accounts.map((e)=>e.toJson()).toList(),
    'currentAccountId': currentAccountId,
    'chats': chats.map((e)=>e.toJson()).toList(),
    'posts': posts.map((e)=>e.toJson()).toList(),
    'gifts': gifts.map((e)=>e.toJson()).toList(),
    'emojiPacks': emojiPacks.map((e)=>e.toJson()).toList(),
    'stories': stories.map((e)=>e.toJson()).toList(),
    'settings': settings.toJson(),
    'reservedUsernames': reservedUsernames.toList(),
  };

  void _fromJson(Map<String,dynamic> d) {
    users..clear()..addAll(((d['users'] as List?)??[]).map((e)=>UserProfile.fromJson(Map<String,dynamic>.from(e as Map))));
    accounts..clear()..addAll(((d['accounts'] as List?)??[]).map((e)=>AccountProfile.fromJson(Map<String,dynamic>.from(e as Map))));
    currentAccountId = '${d['currentAccountId'] ?? ''}';
    chats..clear()..addAll(((d['chats'] as List?)??[]).map((e)=>ChatThread.fromJson(Map<String,dynamic>.from(e as Map))));
    posts..clear()..addAll(((d['posts'] as List?)??[]).map((e)=>PostItem.fromJson(Map<String,dynamic>.from(e as Map))));
    gifts..clear()..addAll(((d['gifts'] as List?)??[]).map((e)=>GiftInstance.fromJson(Map<String,dynamic>.from(e as Map))));
    emojiPacks..clear()..addAll(((d['emojiPacks'] as List?)??[]).map((e)=>EmojiPack.fromJson(Map<String,dynamic>.from(e as Map))));
    stories..clear()..addAll(((d['stories'] as List?)??[]).map((e)=>StoryItem.fromJson(Map<String,dynamic>.from(e as Map))));
    settings = d['settings'] is Map ? AppSettings.fromJson(Map<String,dynamic>.from(d['settings'] as Map)) : AppSettings();
    if (d['reservedUsernames'] is List) reservedUsernames.addAll((d['reservedUsernames'] as List).map((e)=>'$e'));
    if (users.isEmpty || accounts.isEmpty) _seed();
    if (!accounts.any((a)=>a.id == currentAccountId)) currentAccountId = accounts.first.id;
  }

  Future<String?> addAccount(String name, String username) async {
    if (accounts.length >= maxAccounts) {
      return isPlus ? 'Достигнут лимит $maxAccounts аккаунтов' : 'В бесплатной версии доступно 2 аккаунта. OneSpase Plus — до 5.';
    }
    final clean = username.toLowerCase().replaceAll('@','').trim();
    if (clean.length < 3) return 'Username слишком короткий';
    if (reservedUsernames.contains(clean) || users.any((u)=>u.username.toLowerCase()==clean)) return '@$clean уже занят или зарезервирован';
    final uid = 'u_${_id()}';
    final aid = 'acc_${_id()}';
    users.add(UserProfile(id:uid, name:name.trim().isEmpty ? 'Новый пользователь' : name.trim(), username:clean));
    accounts.add(AccountProfile(id:aid, userId:uid, label:'Дополнительный'));
    currentAccountId = aid;
    chats.insert(0, ChatThread(id:'saved_$uid', title:'Избранное', kind:'saved', peerId:uid));
    await save();
    return null;
  }

  Future<void> switchAccount(String id) async { currentAccountId = id; await save(); }
  Future<void> removeAccount(String id) async {
    if (accounts.length <= 1) return;
    final account = accounts.firstWhere((a)=>a.id==id);
    accounts.remove(account);
    if (currentAccountId == id) currentAccountId = accounts.first.id;
    await save();
  }

  Future<String?> updateProfile({required String name, required String username, required String bio, required String status}) async {
    final clean = username.toLowerCase().replaceAll('@','').trim();
    final original = me.username.toLowerCase();
    if (clean != original && (reservedUsernames.contains(clean) || users.any((u)=>u.id != me.id && u.username.toLowerCase()==clean))) return '@$clean недоступен';
    me.name = name.trim().isEmpty ? me.name : name.trim(); me.username = clean; me.bio = bio.trim(); me.status = status.trim().isEmpty ? 'В сети' : status.trim();
    await save(); return null;
  }

  Future<void> customize({required String theme, required String emoji, required String music, required String channel}) async {
    me.theme=theme; me.emojiStatus=emoji.trim(); me.music=music.trim(); me.channel=channel.replaceAll('@','').trim(); await save();
  }

  Future<String?> createEmojiPack(String title, String slug, List<String> items) async {
    if (emojiPacks.length >= maxEmojiPacks) {
      return isPlus ? 'Достигнут лимит $maxEmojiPacks emoji-паков' : 'В бесплатной версии можно создать 3 emoji-пака. OneSpase Plus — до 20.';
    }
    emojiPacks.add(EmojiPack(id:_id(), title:title.trim(), slug:slug.trim().replaceAll(' ','_'), items:items)); await save();
    return null;
  }
  Future<void> deleteEmojiPack(String id) async { emojiPacks.removeWhere((e)=>e.id==id); await save(); }

  Future<void> sendMessage(String chatId, String text, {String? replyTo}) async {
    if (text.trim().isEmpty) return;
    final c=chatById(chatId); c.messages.add(ChatMessage(id:_id(), senderId:me.id, text:text.trim(), sentAt:DateTime.now(), replyTo:replyTo)); c.draft=''; await save();
  }
  Future<void> editMessage(String chatId, String messageId, String text) async { final m=chatById(chatId).messages.firstWhere((m)=>m.id==messageId); m.text=text; m.edited=true; await save(); }
  Future<void> deleteMessage(String chatId, String messageId) async { chatById(chatId).messages.removeWhere((m)=>m.id==messageId); await save(); }
  Future<void> react(String chatId, String messageId, String reaction) async { chatById(chatId).messages.firstWhere((m)=>m.id==messageId).reaction=reaction; await save(); }
  Future<void> setDraft(String chatId, String value) async { chatById(chatId).draft=value; await save(); }
  Future<void> togglePinChat(String chatId) async { final c=chatById(chatId); c.pinned=!c.pinned; await save(); }
  Future<void> toggleArchive(String chatId) async { final c=chatById(chatId); c.archived=!c.archived; await save(); }
  Future<void> toggleMute(String chatId) async { final c=chatById(chatId); c.muted=!c.muted; await save(); }

  Future<void> createPost(String text) async { if(text.trim().isEmpty)return; posts.insert(0, PostItem(id:_id(), authorId:me.id, text:text.trim(), createdAt:DateTime.now())); await save(); }
  Future<void> deletePost(String id) async { posts.removeWhere((p)=>p.id==id && p.authorId==me.id); await save(); }
  Future<void> toggleLike(String id) async { final p=posts.firstWhere((p)=>p.id==id); p.liked=!p.liked; p.likes += p.liked ? 1 : -1; await save(); }
  Future<void> addComment(String id) async { final p=posts.firstWhere((p)=>p.id==id); p.comments++; await save(); }
  Future<void> toggleSavedPost(String id) async { final p=posts.firstWhere((p)=>p.id==id); p.saved=!p.saved; await save(); }

  Future<String?> createStory(String text) async {
    if(text.trim().isEmpty) return 'Story пустая';
    final active = stories.where((s)=>s.authorId==me.id && !s.expired).length;
    if(active >= maxStories) return isPlus ? 'Достигнут лимит $maxStories активных Stories' : 'В бесплатной версии доступно 3 активных Stories. OneSpase Plus — до 20.';
    stories.insert(0, StoryItem(id:_id(), authorId:me.id, text:text.trim(), createdAt:DateTime.now()));
    await save();
    return null;
  }
  Future<void> toggleStoryPin(String id) async { final s=stories.firstWhere((s)=>s.id==id); s.pinned=!s.pinned; await save(); }
  Future<void> deleteStory(String id) async { stories.removeWhere((s)=>s.id==id); await save(); }

  Future<void> follow(String userId) async { final u=userById(userId); u.following=!u.following; await save(); }
  Future<void> block(String userId) async { final u=userById(userId); u.blocked=!u.blocked; await save(); }

  Future<void> sendSecretPacket(String receiverId, {String note=''}) async {
    final next = gifts.where((g)=>g.slug=='secret_packet').length + 1;
    gifts.add(GiftInstance(id:_id(), slug:'secret_packet', senderId:me.id, receiverId:receiverId, serial:next, sentAt:DateTime.now(), note:note)); await save();
  }
  Future<void> toggleGiftPin(String id) async { final g=gifts.firstWhere((g)=>g.id==id); g.pinned=!g.pinned; await save(); }
  Future<void> hideGift(String id) async { gifts.firstWhere((g)=>g.id==id).hidden=true; await save(); }

  Future<void> setPlus(bool value) async { me.plus = value; await save(); }

  Future<void> setVerification(String userId, String value) async { userById(userId).verification=value; await save(); }
  Future<void> reserveUsername(String value) async { final v=value.toLowerCase().replaceAll('@','').trim(); if(v.isNotEmpty) reservedUsernames.add(v); await save(); }

  Future<void> updateSettings() async => save();
  Future<void> clearChatCache() async { for(final c in chats){ if(c.kind!='saved') c.messages.clear(); } await save(); }
  Future<void> resetDemo() async { _seed(); await save(); }
}
