import 'package:flutter/foundation.dart';

enum AnnouncementPriority { low, medium, high, urgent }

extension AnnouncementPriorityExt on AnnouncementPriority {
  String get label {
    switch (this) {
      case AnnouncementPriority.low:
        return 'Low';
      case AnnouncementPriority.medium:
        return 'Medium';
      case AnnouncementPriority.high:
        return 'High';
      case AnnouncementPriority.urgent:
        return 'Urgent';
    }
  }

  static AnnouncementPriority fromString(String v) {
    switch (v.toLowerCase()) {
      case 'medium':
        return AnnouncementPriority.medium;
      case 'high':
        return AnnouncementPriority.high;
      case 'urgent':
        return AnnouncementPriority.urgent;
      default:
        return AnnouncementPriority.low;
    }
  }
}

@immutable
class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.priority = AnnouncementPriority.medium,
    this.expiresAt,
    this.imageUrl,
    this.isPinned = false,
    this.targetRoles,
  });

  final String id;
  final String title;
  final String body;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final AnnouncementPriority priority;
  final DateTime? expiresAt;
  final String? imageUrl;
  final bool isPinned;
  final List<String>? targetRoles; // null = all roles

  bool get isActive =>
      expiresAt == null || DateTime.now().isBefore(expiresAt!);

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) =>
      AnnouncementModel(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        authorId: json['author_id'] as String,
        authorName: json['author_name'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        priority: AnnouncementPriorityExt.fromString(
            json['priority'] as String? ?? 'medium'),
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        imageUrl: json['image_url'] as String?,
        isPinned: json['is_pinned'] as bool? ?? false,
        targetRoles: json['target_roles'] != null
            ? List<String>.from(json['target_roles'] as List)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'author_id': authorId,
        'author_name': authorName,
        'created_at': createdAt.toIso8601String(),
        'priority': priority.label.toLowerCase(),
        'expires_at': expiresAt?.toIso8601String(),
        'image_url': imageUrl,
        'is_pinned': isPinned,
        'target_roles': targetRoles,
      };
}
