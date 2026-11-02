class EmojiPack {
  const EmojiPack({
    required this.id,
    required this.title,
    required this.slug,
    required this.emojis,
    this.isPublic = true,
  });

  final String id;
  final String title;
  final String slug;
  final List<String> emojis;
  final bool isPublic;

  factory EmojiPack.fromJson(Map<String, dynamic> json) {
    final raw = json['emojis'];
    return EmojiPack(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Emoji Pack',
      slug: json['slug']?.toString() ?? 'pack',
      emojis: raw is List
          ? raw.map((value) => value.toString()).toList(growable: false)
          : const [],
      isPublic: json['is_public'] != false,
    );
  }
}
