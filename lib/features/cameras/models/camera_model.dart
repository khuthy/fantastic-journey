import 'package:flutter/foundation.dart';

enum CameraStatus { online, offline, maintenance }
enum CameraLocation { mainGate, exitGate, parkingLot, perimeter, communal }

extension CameraLocationExt on CameraLocation {
  String get label {
    switch (this) {
      case CameraLocation.mainGate:
        return 'Main Gate';
      case CameraLocation.exitGate:
        return 'Exit Gate';
      case CameraLocation.parkingLot:
        return 'Parking Lot';
      case CameraLocation.perimeter:
        return 'Perimeter';
      case CameraLocation.communal:
        return 'Communal Area';
    }
  }

  static CameraLocation fromString(String v) {
    switch (v.toLowerCase()) {
      case 'exit_gate':
        return CameraLocation.exitGate;
      case 'parking_lot':
        return CameraLocation.parkingLot;
      case 'perimeter':
        return CameraLocation.perimeter;
      case 'communal':
        return CameraLocation.communal;
      default:
        return CameraLocation.mainGate;
    }
  }
}

@immutable
class CameraModel {
  const CameraModel({
    required this.id,
    required this.name,
    required this.location,
    required this.streamUrl,
    required this.status,
    required this.installedAt,
    this.thumbnailUrl,
    this.lastFootageKey,
    this.lastOnlineAt,
    this.ipAddress,
    this.model,
    this.isRecording = false,
    this.r2BucketPath,
  });

  final String id;
  final String name;
  final CameraLocation location;
  final String streamUrl;
  final CameraStatus status;
  final DateTime installedAt;
  final String? thumbnailUrl;
  final String? lastFootageKey; // Cloudflare R2 object key
  final DateTime? lastOnlineAt;
  final String? ipAddress;
  final String? model;
  final bool isRecording;
  final String? r2BucketPath;

  factory CameraModel.fromJson(Map<String, dynamic> json) => CameraModel(
        id: json['id'] as String,
        name: json['name'] as String,
        location:
            CameraLocationExt.fromString(json['location'] as String),
        streamUrl: json['stream_url'] as String,
        status: _statusFromString(json['status'] as String),
        installedAt: DateTime.parse(json['installed_at'] as String),
        thumbnailUrl: json['thumbnail_url'] as String?,
        lastFootageKey: json['last_footage_key'] as String?,
        lastOnlineAt: json['last_online_at'] != null
            ? DateTime.parse(json['last_online_at'] as String)
            : null,
        ipAddress: json['ip_address'] as String?,
        model: json['model'] as String?,
        isRecording: json['is_recording'] as bool? ?? false,
        r2BucketPath: json['r2_bucket_path'] as String?,
      );

  static CameraStatus _statusFromString(String v) {
    switch (v.toLowerCase()) {
      case 'offline':
        return CameraStatus.offline;
      case 'maintenance':
        return CameraStatus.maintenance;
      default:
        return CameraStatus.online;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'location': location.label.toLowerCase().replaceAll(' ', '_'),
        'stream_url': streamUrl,
        'status': status.name,
        'installed_at': installedAt.toIso8601String(),
        'thumbnail_url': thumbnailUrl,
        'last_footage_key': lastFootageKey,
        'last_online_at': lastOnlineAt?.toIso8601String(),
        'ip_address': ipAddress,
        'model': model,
        'is_recording': isRecording,
        'r2_bucket_path': r2BucketPath,
      };
}

@immutable
class FootageRecord {
  const FootageRecord({
    required this.id,
    required this.cameraId,
    required this.r2Key,
    required this.startTime,
    required this.endTime,
    required this.fileSizeBytes,
    this.thumbnailKey,
    this.durationSeconds,
  });

  final String id;
  final String cameraId;
  final String r2Key;
  final DateTime startTime;
  final DateTime endTime;
  final int fileSizeBytes;
  final String? thumbnailKey;
  final int? durationSeconds;

  factory FootageRecord.fromJson(Map<String, dynamic> json) => FootageRecord(
        id: json['id'] as String,
        cameraId: json['camera_id'] as String,
        r2Key: json['r2_key'] as String,
        startTime: DateTime.parse(json['start_time'] as String),
        endTime: DateTime.parse(json['end_time'] as String),
        fileSizeBytes: json['file_size_bytes'] as int,
        thumbnailKey: json['thumbnail_key'] as String?,
        durationSeconds: json['duration_seconds'] as int?,
      );
}
