class SocialProfile {
  const SocialProfile({
    required this.id,
    required this.displayName,
    required this.username,
    required this.status,
    this.bio = '',
    this.avatarUrl,
    this.online = false,
    this.verification = 'none',
    this.profileTheme = 'purple',
    this.emojiStatus = '',
    this.musicTitle = '',
    this.featuredChannel = '',
  });

  final String id;
  final String displayName;
  final String username;
  final String status;
  final String bio;
  final String? avatarUrl;
  final bool online;
  final String verification;
  final String profileTheme;
  final String emojiStatus;
  final String musicTitle;
  final String featuredChannel;

  bool get isVerified => verification != 'none';

  factory SocialProfile.fromJson(Map<String, dynamic> json) {
    return SocialProfile(
      id: json['id']?.toString() ?? json['peer_id']?.toString() ?? '',
      displayName: json['display_name']?.toString() ??
          json['peer_name']?.toString() ??
          'Пользователь',
      username: json['username']?.toString() ??
          json['peer_username']?.toString() ??
          'user',
      status: json['status']?.toString() ??
          json['peer_status']?.toString() ??
          'В OneSpase',
      bio: json['bio']?.toString() ?? '',
      avatarUrl: json['avatar_url']?.toString(),
      online: json['online'] == true || json['peer_online'] == true,
      verification: json['verification']?.toString() ?? 'none',
      profileTheme: json['profile_theme']?.toString() ?? 'purple',
      emojiStatus: json['emoji_status']?.toString() ?? '',
      musicTitle: json['music_title']?.toString() ?? '',
      featuredChannel: json['featured_channel']?.toString() ?? '',
    );
  }
}
