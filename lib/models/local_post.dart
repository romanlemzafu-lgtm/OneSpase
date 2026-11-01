class LocalPost {
  LocalPost({
    required this.id,
    required this.author,
    required this.text,
    required this.createdAt,
    this.likes = 0,
    this.likedByMe = false,
    List<String>? comments,
  }) : comments = comments ?? [];

  final String id;
  final String author;
  final String text;
  final DateTime createdAt;
  int likes;
  bool likedByMe;
  final List<String> comments;

  Map<String, dynamic> toJson() => {
        'id': id,
        'author': author,
        'text': text,
        'createdAt': createdAt.toIso8601String(),
        'likes': likes,
        'likedByMe': likedByMe,
        'comments': comments,
      };

  factory LocalPost.fromJson(Map<String, dynamic> json) {
    return LocalPost(
      id: json['id'] as String,
      author: json['author'] as String,
      text: json['text'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      likedByMe: json['likedByMe'] as bool? ?? false,
      comments: (json['comments'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
    );
  }
}
