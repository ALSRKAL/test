class User {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;
  final bool isActive;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });
}
