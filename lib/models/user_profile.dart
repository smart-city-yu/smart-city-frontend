class UserProfile {
  final String initials;
  final String fullName;
  final String email;
  final String phone;

  const UserProfile({
    required this.initials,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final fullName = (json['fullName'] as String? ?? '').trim();
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : fullName.isNotEmpty
            ? fullName[0].toUpperCase()
            : '?';
    return UserProfile(
      initials: initials,
      fullName: fullName,
      email: json['email'] as String? ?? '',
      phone: json['phoneNumber'] as String? ?? '',
    );
  }
}