import 'dart:math';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

abstract final class AppHelpers {
  static final _random = Random.secure();

  /// Generate a 6-digit numeric OTP
  static String generateOtp() {
    return (100000 + _random.nextInt(900000)).toString();
  }

  /// Generate a secure alphanumeric token (for QR payloads)
  static String generateToken({int length = 32}) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(length, (_) => chars[_random.nextInt(chars.length)])
        .join();
  }

  /// Hash a value with SHA-256
  static String hashValue(String value) {
    final bytes = utf8.encode(value);
    return sha256.convert(bytes).toString();
  }

  /// Format a DateTime to a readable date string
  static String formatDate(DateTime date) =>
      DateFormat('dd MMM yyyy').format(date);

  /// Format a DateTime to a readable time string
  static String formatTime(DateTime date) =>
      DateFormat('HH:mm').format(date);

  /// Format a DateTime to full readable string
  static String formatDateTime(DateTime date) =>
      DateFormat('dd MMM yyyy, HH:mm').format(date);

  /// Format a DateTime relative (e.g. "2 hours ago")
  static String relativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }

  /// Returns initials from a full name (max 2 chars)
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  /// Mask a phone number for display: +27 ** *** 5678
  static String maskPhone(String phone) {
    if (phone.length < 4) return phone;
    return '${phone.substring(0, 3)} ** *** ${phone.substring(phone.length - 4)}';
  }

  /// Show a snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade700 : null,
          duration: duration,
        ),
      );
  }

  /// Determine if device is in compact (mobile) layout
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= 600 && w < 900;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  /// Safe navigation pop
  static void popIfCan(BuildContext context) {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Expiry display for OTP/QR
  static String expiryLabel(DateTime expiry) {
    final diff = expiry.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inMinutes < 1) return 'Expires in ${diff.inSeconds}s';
    if (diff.inHours < 1) return 'Expires in ${diff.inMinutes}m';
    return 'Expires ${formatDate(expiry)}';
  }
}
