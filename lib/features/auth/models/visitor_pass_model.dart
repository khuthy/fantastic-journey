import 'package:flutter/foundation.dart';

enum PassType { qr, otp }
enum PassStatus { active, used, expired, revoked }

extension PassStatusExt on PassStatus {
  String get label {
    switch (this) {
      case PassStatus.active:
        return 'Active';
      case PassStatus.used:
        return 'Used';
      case PassStatus.expired:
        return 'Expired';
      case PassStatus.revoked:
        return 'Revoked';
    }
  }

  static PassStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'used':
        return PassStatus.used;
      case 'expired':
        return PassStatus.expired;
      case 'revoked':
        return PassStatus.revoked;
      default:
        return PassStatus.active;
    }
  }
}

@immutable
class VisitorPassModel {
  const VisitorPassModel({
    required this.id,
    required this.residentId,
    required this.visitorName,
    required this.visitorPhone,
    required this.passType,
    required this.token,
    required this.createdAt,
    required this.expiresAt,
    this.status = PassStatus.active,
    this.vehicleRegistration,
    this.purpose,
    this.usedAt,
    this.usedByGuardId,
    this.maxUses = 1,
    this.useCount = 0,
    this.notes,
  });

  final String id;
  final String residentId;
  final String visitorName;
  final String visitorPhone;
  final PassType passType;
  final String token;   // QR payload or OTP code
  final DateTime createdAt;
  final DateTime expiresAt;
  final PassStatus status;
  final String? vehicleRegistration;
  final String? purpose;
  final DateTime? usedAt;
  final String? usedByGuardId;
  final int maxUses;
  final int useCount;
  final String? notes;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => status == PassStatus.active && !isExpired;
  bool get hasRemainingUses => useCount < maxUses;

  factory VisitorPassModel.fromJson(Map<String, dynamic> json) =>
      VisitorPassModel(
        id: json['id'] as String,
        residentId: json['resident_id'] as String,
        visitorName: json['visitor_name'] as String,
        visitorPhone: json['visitor_phone'] as String,
        passType:
            json['pass_type'] == 'otp' ? PassType.otp : PassType.qr,
        token: json['token'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
        status: PassStatusExt.fromString(json['status'] as String),
        vehicleRegistration: json['vehicle_registration'] as String?,
        purpose: json['purpose'] as String?,
        usedAt: json['used_at'] != null
            ? DateTime.parse(json['used_at'] as String)
            : null,
        usedByGuardId: json['used_by_guard_id'] as String?,
        maxUses: json['max_uses'] as int? ?? 1,
        useCount: json['use_count'] as int? ?? 0,
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'resident_id': residentId,
        'visitor_name': visitorName,
        'visitor_phone': visitorPhone,
        'pass_type': passType == PassType.otp ? 'otp' : 'qr',
        'token': token,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'status': status.label.toLowerCase(),
        'vehicle_registration': vehicleRegistration,
        'purpose': purpose,
        'used_at': usedAt?.toIso8601String(),
        'used_by_guard_id': usedByGuardId,
        'max_uses': maxUses,
        'use_count': useCount,
        'notes': notes,
      };

  VisitorPassModel copyWith({
    PassStatus? status,
    DateTime? usedAt,
    String? usedByGuardId,
    int? useCount,
  }) =>
      VisitorPassModel(
        id: id,
        residentId: residentId,
        visitorName: visitorName,
        visitorPhone: visitorPhone,
        passType: passType,
        token: token,
        createdAt: createdAt,
        expiresAt: expiresAt,
        status: status ?? this.status,
        vehicleRegistration: vehicleRegistration,
        purpose: purpose,
        usedAt: usedAt ?? this.usedAt,
        usedByGuardId: usedByGuardId ?? this.usedByGuardId,
        maxUses: maxUses,
        useCount: useCount ?? this.useCount,
        notes: notes,
      );
}
