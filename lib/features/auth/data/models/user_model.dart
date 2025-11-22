import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatar,
    required super.role,
    required super.isActive,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Convert HTTP to HTTPS for security
    String? avatarUrl = json['avatar'];
    if (avatarUrl != null && avatarUrl.startsWith('http://')) {
      avatarUrl = avatarUrl.replaceFirst('http://', 'https://');
    }
    
    return UserModel(
      id: json['_id'] ?? json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatar: avatarUrl,
      role: json['role'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'role': role,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
