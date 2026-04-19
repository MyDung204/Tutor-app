class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String? avatarUrl;
  final Map<String, dynamic>? tutorProfile;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.tutorProfile,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      avatarUrl: json['avatar_url'],
      tutorProfile: json['tutor_profile'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatar_url': avatarUrl,
      'tutor_profile': tutorProfile,
    };
  }
}
