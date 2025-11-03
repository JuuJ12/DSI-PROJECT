import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final DateTime? dateOfBirth;
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
    DateTime? dateOfBirth,
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
    final createdRaw = map['createdAt'];
    final DateTime createdAt = switch (createdRaw) {
      Timestamp ts => ts.toDate(),
      int ms => DateTime.fromMillisecondsSinceEpoch(ms),
      String iso => DateTime.tryParse(iso) ?? DateTime.now(),
      _ => DateTime.now(),
    };

    // dateOfBirth: aceita Timestamp (novo), int ms (legado) ou String ISO (legado)
    final dobRaw = map['dateOfBirth'];
    final DateTime? dob = switch (dobRaw) {
      Timestamp ts => ts.toDate(),
      int ms => DateTime.fromMillisecondsSinceEpoch(ms),
      String iso => DateTime.tryParse(iso),
      _ => null,
    };
    
    return UserModel(
      id: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String?,
      dateOfBirth: dob,
      createdAt: createdAt,
      extra: map['extra'] != null ? Map<String, dynamic>.from(map['extra']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      // Salva como Timestamp no Firestore
      'dateOfBirth': dateOfBirth != null ? Timestamp.fromDate(dateOfBirth!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'extra': extra,
    };
  }
}