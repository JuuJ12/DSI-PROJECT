class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? dateOfBirth;
  final DateTime createdAt;
  final Map<String, dynamic>? extra; // campos adicionais

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.dateOfBirth,
    DateTime? createdAt,
    this.extra,
  }) : createdAt = createdAt ?? DateTime.now();

  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? dateOfBirth,
    DateTime? createdAt,
    Map<String, dynamic>? extra,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      createdAt: createdAt ?? this.createdAt,
      extra: extra ?? this.extra,
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      dateOfBirth: map['dateOfBirth'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      extra: map['extra'] != null ? Map<String, dynamic>.from(map['extra']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'dateOfBirth': dateOfBirth,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'extra': extra,
    };
  }
}