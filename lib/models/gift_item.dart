class GiftItem {
  const GiftItem({
    required this.id,
    required this.slug,
    required this.title,
    required this.emoji,
    required this.rarity,
    required this.accent,
    this.description = '',
    this.serialNumber,
    this.senderName,
    this.receivedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String emoji;
  final String rarity;
  final String accent;
  final String description;
  final int? serialNumber;
  final String? senderName;
  final DateTime? receivedAt;

  factory GiftItem.fromJson(Map<String, dynamic> json) => GiftItem(
        id: json['id']?.toString() ?? '',
        slug: json['slug']?.toString() ?? 'gift',
        title: json['title']?.toString() ?? 'Подарок',
        emoji: json['emoji']?.toString() ?? '🎁',
        rarity: json['rarity']?.toString() ?? 'common',
        accent: json['accent']?.toString() ?? 'purple',
        description: json['description']?.toString() ?? '',
        serialNumber: json['serial_number'] is int
            ? json['serial_number'] as int
            : int.tryParse(json['serial_number']?.toString() ?? ''),
        senderName: json['sender_name']?.toString(),
        receivedAt: json['received_at'] == null
            ? null
            : DateTime.tryParse(json['received_at'].toString()),
      );
}
