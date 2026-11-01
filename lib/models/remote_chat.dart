class RemoteConversation {
  const RemoteConversation({
    required this.id,
    required this.peerId,
    required this.peerName,
    required this.peerUsername,
    required this.peerStatus,
    required this.peerOnline,
    required this.verification,
    required this.lastMessage,
    required this.lastMessageAt,
  });

  final String id;
  final String peerId;
  final String peerName;
  final String peerUsername;
  final String peerStatus;
  final bool peerOnline;
  final String verification;
  final String lastMessage;
  final DateTime? lastMessageAt;

  factory RemoteConversation.fromJson(Map<String, dynamic> json) {
    return RemoteConversation(
      id: json['conversation_id']?.toString() ?? '',
      peerId: json['peer_id']?.toString() ?? '',
      peerName: json['peer_name']?.toString() ?? 'Пользователь',
      peerUsername: json['peer_username']?.toString() ?? 'user',
      peerStatus: json['peer_status']?.toString() ?? 'В OneSpase',
      peerOnline: json['peer_online'] == true,
      verification: json['verification']?.toString() ?? 'none',
      lastMessage: json['last_message']?.toString() ?? '',
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.tryParse(json['last_message_at'].toString()),
    );
  }
}

class RemoteMessage {
  const RemoteMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.editedAt,
    this.readAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;
  final DateTime? editedAt;
  final DateTime? readAt;

  factory RemoteMessage.fromJson(Map<String, dynamic> json) {
    return RemoteMessage(
      id: json['id']?.toString() ?? '',
      conversationId: json['conversation_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      editedAt: json['edited_at'] == null
          ? null
          : DateTime.tryParse(json['edited_at'].toString()),
      readAt: json['read_at'] == null
          ? null
          : DateTime.tryParse(json['read_at'].toString()),
    );
  }
}
