class ChatMessage {
  ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.fromMe,
  });

  final String id;
  final String text;
  final DateTime sentAt;
  final bool fromMe;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'sentAt': sentAt.toIso8601String(),
        'fromMe': fromMe,
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      text: json['text'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      fromMe: json['fromMe'] as bool? ?? false,
    );
  }
}
