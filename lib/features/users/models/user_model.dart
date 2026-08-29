class UserModel {
  final int? id;
  final String username;
  final String passwordHash;
  final String role; // 'admin' or 'cashier'
  final DateTime? createdAt;

  const UserModel({
    this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  factory UserModel.fromMap(Map<String, Object?> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String,
      passwordHash: map['password_hash'] as String,
      role: map['role'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      'password_hash': passwordHash,
      'role': role,
      // created_at intentionally omitted — DB default handles it on insert.
    };
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      role: role ?? this.role,
      createdAt: createdAt,
    );
  }
}
