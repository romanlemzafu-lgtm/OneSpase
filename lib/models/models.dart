class UserProfile {
  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    this.bio = 'Моё пространство в OneSpase 🚀',
    this.status = 'В сети',
    this.verification = 'none',
    this.emojiStatus = '',
    this.music = '',
    this.channel = '',
    this.theme = 'purple',
    this.following = false,
    this.blocked = false,
    this.plus = false,
  });

  String id;
  String name;
  String username;
  String bio;
  String status;
  String verification;
  String emojiStatus;
  String music;
  String channel;
  String theme;
  bool following;
  bool blocked;
  bool plus;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'bio': bio,
        'status': status,
        'verification': verification,
        'emojiStatus': emojiStatus,
        'music': music,
        'channel': channel,
        'theme': theme,
        'following': following,
        'blocked': blocked,
        'plus': plus,
      };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: '${j['id']}',
        name: '${j['name']}',
        username: '${j['username']}',
        bio: '${j['bio'] ?? ''}',
        status: '${j['status'] ?? 'В сети'}',
        verification: '${j['verification'] ?? 'none'}',
        emojiStatus: '${j['emojiStatus'] ?? ''}',
        music: '${j['music'] ?? ''}',
        channel: '${j['channel'] ?? ''}',
        theme: '${j['theme'] ?? 'purple'}',
        following: j['following'] == true,
        blocked: j['blocked'] == true,
        plus: j['plus'] == true,
      );
}

class AccountProfile {
  AccountProfile({required this.id, required this.userId, required this.label});
  String id;
  String userId;
  String label;
  Map<String, dynamic> toJson() => {'id': id, 'userId': userId, 'label': label};
  factory AccountProfile.fromJson(Map<String, dynamic> j) => AccountProfile(id: '${j['id']}', userId: '${j['userId']}', label: '${j['label']}');
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.edited = false,
    this.read = true,
    this.replyTo,
    this.reaction = '',
  });
  String id;
  String senderId;
  String text;
  DateTime sentAt;
  bool edited;
  bool read;
  String? replyTo;
  String reaction;
  Map<String, dynamic> toJson() => {
        'id': id,
        'senderId': senderId,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        'edited': edited,
        'read': read,
        'replyTo': replyTo,
        'reaction': reaction,
      };
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: '${j['id']}', senderId: '${j['senderId']}', text: '${j['text']}', sentAt: DateTime.tryParse('${j['sentAt']}') ?? DateTime.now(),
        edited: j['edited'] == true, read: j['read'] != false, replyTo: j['replyTo']?.toString(), reaction: '${j['reaction'] ?? ''}',
      );
}

class ChatThread {
  ChatThread({required this.id, required this.title, required this.kind, required this.peerId, List<ChatMessage>? messages}) : messages = messages ?? [];
  String id;
  String title;
  String kind;
  String peerId;
  List<ChatMessage> messages;
  bool pinned = false;
  bool archived = false;
  bool muted = false;
  String draft = '';
  Map<String, dynamic> toJson() => {
        'id': id, 'title': title, 'kind': kind, 'peerId': peerId,
        'messages': messages.map((e) => e.toJson()).toList(),
        'pinned': pinned, 'archived': archived, 'muted': muted, 'draft': draft,
      };
  factory ChatThread.fromJson(Map<String, dynamic> j) {
    final t = ChatThread(
      id: '${j['id']}', title: '${j['title']}', kind: '${j['kind'] ?? 'personal'}', peerId: '${j['peerId'] ?? ''}',
      messages: ((j['messages'] as List?) ?? []).map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
    );
    t.pinned = j['pinned'] == true; t.archived = j['archived'] == true; t.muted = j['muted'] == true; t.draft = '${j['draft'] ?? ''}';
    return t;
  }
}

class PostItem {
  PostItem({required this.id, required this.authorId, required this.text, required this.createdAt, this.likes = 0, this.liked = false, this.comments = 0, this.saved = false});
  String id; String authorId; String text; DateTime createdAt; int likes; bool liked; int comments; bool saved;
  Map<String, dynamic> toJson() => {'id': id, 'authorId': authorId, 'text': text, 'createdAt': createdAt.toIso8601String(), 'likes': likes, 'liked': liked, 'comments': comments, 'saved': saved};
  factory PostItem.fromJson(Map<String, dynamic> j) => PostItem(id: '${j['id']}', authorId: '${j['authorId']}', text: '${j['text']}', createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(), likes: j['likes'] as int? ?? 0, liked: j['liked'] == true, comments: j['comments'] as int? ?? 0, saved: j['saved'] == true);
}

class GiftInstance {
  GiftInstance({required this.id, required this.slug, required this.senderId, required this.receiverId, required this.serial, required this.sentAt, this.note = '', this.pinned = false, this.hidden = false});
  String id; String slug; String senderId; String receiverId; int serial; DateTime sentAt; String note; bool pinned; bool hidden;
  Map<String, dynamic> toJson() => {'id': id, 'slug': slug, 'senderId': senderId, 'receiverId': receiverId, 'serial': serial, 'sentAt': sentAt.toIso8601String(), 'note': note, 'pinned': pinned, 'hidden': hidden};
  factory GiftInstance.fromJson(Map<String, dynamic> j) => GiftInstance(id: '${j['id']}', slug: '${j['slug']}', senderId: '${j['senderId']}', receiverId: '${j['receiverId']}', serial: j['serial'] as int? ?? 1, sentAt: DateTime.tryParse('${j['sentAt']}') ?? DateTime.now(), note: '${j['note'] ?? ''}', pinned: j['pinned'] == true, hidden: j['hidden'] == true);
}

class EmojiPack {
  EmojiPack({required this.id, required this.title, required this.slug, required this.items});
  String id; String title; String slug; List<String> items;
  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'slug': slug, 'items': items};
  factory EmojiPack.fromJson(Map<String, dynamic> j) => EmojiPack(id: '${j['id']}', title: '${j['title']}', slug: '${j['slug']}', items: ((j['items'] as List?) ?? []).map((e) => '$e').toList());
}

class StoryItem {
  StoryItem({required this.id, required this.authorId, required this.text, required this.createdAt, this.pinned = false});
  String id; String authorId; String text; DateTime createdAt; bool pinned;
  bool get expired => !pinned && DateTime.now().difference(createdAt).inHours >= 24;
  Map<String, dynamic> toJson() => {'id': id, 'authorId': authorId, 'text': text, 'createdAt': createdAt.toIso8601String(), 'pinned': pinned};
  factory StoryItem.fromJson(Map<String, dynamic> j) => StoryItem(id: '${j['id']}', authorId: '${j['authorId']}', text: '${j['text']}', createdAt: DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(), pinned: j['pinned'] == true);
}

class AppSettings {
  String onlineVisibility = 'Все';
  String lastSeenVisibility = 'Друзья';
  String messagePermission = 'Все';
  String callPermission = 'Друзья';
  bool notifMessages = true;
  bool notifReactions = true;
  bool notifGifts = true;
  bool notifCommunities = true;
  bool notifSound = true;
  bool notifVibration = true;
  bool previewText = true;
  bool autoPhoto = true;
  bool autoVideo = false;
  bool autoFiles = false;
  bool dataSaver = false;

  Map<String, dynamic> toJson() => {
        'onlineVisibility': onlineVisibility, 'lastSeenVisibility': lastSeenVisibility, 'messagePermission': messagePermission, 'callPermission': callPermission,
        'notifMessages': notifMessages, 'notifReactions': notifReactions, 'notifGifts': notifGifts, 'notifCommunities': notifCommunities,
        'notifSound': notifSound, 'notifVibration': notifVibration, 'previewText': previewText,
        'autoPhoto': autoPhoto, 'autoVideo': autoVideo, 'autoFiles': autoFiles, 'dataSaver': dataSaver,
      };
  factory AppSettings.fromJson(Map<String, dynamic> j) {
    final s = AppSettings();
    s.onlineVisibility = '${j['onlineVisibility'] ?? 'Все'}'; s.lastSeenVisibility = '${j['lastSeenVisibility'] ?? 'Друзья'}';
    s.messagePermission = '${j['messagePermission'] ?? 'Все'}'; s.callPermission = '${j['callPermission'] ?? 'Друзья'}';
    s.notifMessages = j['notifMessages'] != false; s.notifReactions = j['notifReactions'] != false; s.notifGifts = j['notifGifts'] != false; s.notifCommunities = j['notifCommunities'] != false;
    s.notifSound = j['notifSound'] != false; s.notifVibration = j['notifVibration'] != false; s.previewText = j['previewText'] != false;
    s.autoPhoto = j['autoPhoto'] != false; s.autoVideo = j['autoVideo'] == true; s.autoFiles = j['autoFiles'] == true; s.dataSaver = j['dataSaver'] == true;
    return s;
  }
}
