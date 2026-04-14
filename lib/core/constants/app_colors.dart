import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand
  static const Color primary = Color(0xFF0D2137);
  static const Color primaryLight = Color(0xFF1A3A5C);
  static const Color primaryDark = Color(0xFF070F1A);

  static const Color accent = Color(0xFFF5A623);
  static const Color accentLight = Color(0xFFFFC85A);
  static const Color accentDark = Color(0xFFD4881A);

  // Semantic
  static const Color success = Color(0xFF2ECC71);
  static const Color successLight = Color(0xFFD5F5E3);
  static const Color warning = Color(0xFFF39C12);
  static const Color warningLight = Color(0xFFFEF9E7);
  static const Color error = Color(0xFFE74C3C);
  static const Color errorLight = Color(0xFFFDEDEB);
  static const Color info = Color(0xFF3498DB);
  static const Color infoLight = Color(0xFFEBF5FB);

  // Neutral — light mode
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F7FA);
  static const Color background = Color(0xFFF0F4F8);
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF2F7);

  // Neutral — dark mode
  static const Color darkSurface = Color(0xFF1A2332);
  static const Color darkSurfaceVariant = Color(0xFF243447);
  static const Color darkBackground = Color(0xFF0D1B2A);
  static const Color darkBorder = Color(0xFF2D4059);

  // Text
  static const Color textPrimary = Color(0xFF0D2137);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnAccent = Color(0xFF0D2137);

  // Role badges
  static const Color residentBadge = Color(0xFF6366F1);
  static const Color securityBadge = Color(0xFF059669);
  static const Color adminBadge = Color(0xFFDC2626);

  // Gate status
  static const Color gateOpen = Color(0xFF2ECC71);
  static const Color gateClosed = Color(0xFFE74C3C);
  static const Color gatePending = Color(0xFFF39C12);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLight, primary],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentLight, accent],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A3A5C), Color(0xFF0D2137)],
  );
}
