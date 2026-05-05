class User {
  final String id;
  final String username;
  final String email;
  final String role; // 'user' | 'admin'

  User({
    required this.id,
    required this.username,
    required this.email,
    this.role = 'user',
  });

  bool get isAdmin => role == 'admin';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
    };
  }
}
