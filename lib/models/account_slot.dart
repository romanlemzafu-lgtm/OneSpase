class AccountSlot {
  const AccountSlot({
    required this.userId,
    required this.label,
    required this.username,
    this.email,
  });

  final String userId;
  final String label;
  final String username;
  final String? email;

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'label': label,
        'username': username,
        'email': email,
      };

  factory AccountSlot.fromJson(Map<String, dynamic> json) => AccountSlot(
        userId: json['userId']?.toString() ?? '',
        label: json['label']?.toString() ?? 'OneSpase',
        username: json['username']?.toString() ?? 'user',
        email: json['email']?.toString(),
      );
}
