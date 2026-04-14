import 'package:flutter/foundation.dart';

enum UserRole { resident, security, admin }

extension UserRoleExt on UserRole {
  String get label {
    switch (this) {
      case UserRole.resident:
        return 'Resident';
      case UserRole.security:
        return 'Security Guard';
      case UserRole.admin:
        return 'Administrator';
    }
  }

  String get dbValue {
    switch (this) {
      case UserRole.resident:
        return 'resident';
      case UserRole.security:
        return 'security';
      case UserRole.admin:
        return 'admin';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'security':
        return UserRole.security;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.resident;
    }
  }
}

@immutable
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    required this.unitNumber,
    required this.createdAt,
    this.avatarUrl,
    this.vehicleRegistration,
    this.isVerified = false,
    this.isActive = true,
    this.lastLoginAt,
    this.idNumber,
  });

  final String id;
  final String email;
  final String fullName;
  final String phone;
  final UserRole role;
  final String unitNumber;
  final DateTime createdAt;
  final String? avatarUrl;
  final String? vehicleRegistration;
  final bool isVerified;
  final bool isActive;
  final DateTime? lastLoginAt;
  final String? idNumber;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        phone: json['phone'] as String,
        role: UserRoleExt.fromString(json['role'] as String),
        unitNumber: json['unit_number'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        avatarUrl: json['avatar_url'] as String?,
        vehicleRegistration: json['vehicle_registration'] as String?,
        isVerified: json['is_verified'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? true,
        lastLoginAt: json['last_login_at'] != null
            ? DateTime.parse(json['last_login_at'] as String)
            : null,
        idNumber: json['id_number'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'role': role.dbValue,
        'unit_number': unitNumber,
        'created_at': createdAt.toIso8601String(),
        'avatar_url': avatarUrl,
        'vehicle_registration': vehicleRegistration,
        'is_verified': isVerified,
        'is_active': isActive,
        'last_login_at': lastLoginAt?.toIso8601String(),
        'id_number': idNumber,
      };

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phone,
    UserRole? role,
    String? unitNumber,
    DateTime? createdAt,
    String? avatarUrl,
    String? vehicleRegistration,
    bool? isVerified,
    bool? isActive,
    DateTime? lastLoginAt,
    String? idNumber,
  }) =>
      UserModel(
        id: id ?? this.id,
        email: email ?? this.email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        unitNumber: unitNumber ?? this.unitNumber,
        createdAt: createdAt ?? this.createdAt,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        vehicleRegistration: vehicleRegistration ?? this.vehicleRegistration,
        isVerified: isVerified ?? this.isVerified,
        isActive: isActive ?? this.isActive,
        lastLoginAt: lastLoginAt ?? this.lastLoginAt,
        idNumber: idNumber ?? this.idNumber,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
