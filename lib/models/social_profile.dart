class SocialProfile {
  const SocialProfile({
    required this.id,
    required this.displayName,
    required this.username,
    required this.status,
    this.bio = '',
    this.avatarUrl,
    this.online = false,
  });

  final String id;
  final String displayName;
  final String username;
  final String status;
  final String bio;
  final String? avatarUrl;
  final bool online;

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    return SocialProfile(
      id: json['id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ?? 'Пользователь',
      username: json['username']?.toString() ?? 'user',
      status: json['status']?.toString() ?? 'В OneSpase',
      bio: json['bio']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      online: json['online'] == true,
    );
  }
}
