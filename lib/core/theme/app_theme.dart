import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

abstract final class AppTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _lightColorScheme,
        textTheme: _textTheme(AppColors.textPrimary),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: _appBarTheme(
          background: AppColors.surface,
          foreground: AppColors.textPrimary,
        ),
        cardTheme: _cardTheme(AppColors.surface),
        elevatedButtonTheme: _elevatedButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(),
        textButtonTheme: _textButtonTheme(),
        inputDecorationTheme: _inputDecorationTheme(),
        chipTheme: _chipTheme(),
        bottomNavigationBarTheme: _bottomNavTheme(),
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 1,
        ),
        dialogTheme: _dialogTheme(AppColors.surface),
        snackBarTheme: _snackBarTheme(),
        switchTheme: _switchTheme(),
        checkboxTheme: _checkboxTheme(),
        extensions: const [AppThemeExtension.light],
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _darkColorScheme,
        textTheme: _textTheme(AppColors.textOnDark),
        scaffoldBackgroundColor: AppColors.darkBackground,
        appBarTheme: _appBarTheme(
          background: AppColors.darkSurface,
          foreground: AppColors.textOnDark,
        ),
        cardTheme: _cardTheme(AppColors.darkSurface),
        elevatedButtonTheme: _elevatedButtonTheme(),
        outlinedButtonTheme: _outlinedButtonTheme(dark: true),
        textButtonTheme: _textButtonTheme(),
        inputDecorationTheme: _inputDecorationTheme(dark: true),
        chipTheme: _chipTheme(dark: true),
        bottomNavigationBarTheme: _bottomNavTheme(dark: true),
        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder,
          thickness: 1,
          space: 1,
        ),
        dialogTheme: _dialogTheme(AppColors.darkSurface),
        snackBarTheme: _snackBarTheme(dark: true),
        switchTheme: _switchTheme(),
        checkboxTheme: _checkboxTheme(),
        extensions: const [AppThemeExtension.dark],
      );

  static ColorScheme get _lightColorScheme => const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.textOnDark,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.accent,
        onSecondary: AppColors.textOnAccent,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: AppColors.textOnDark,
        outline: AppColors.border,
      );

  static ColorScheme get _darkColorScheme => const ColorScheme.dark(
        primary: AppColors.accent,
        onPrimary: AppColors.textOnAccent,
        primaryContainer: AppColors.primaryLight,
        secondary: AppColors.accentLight,
        onSecondary: AppColors.textOnAccent,
        surface: AppColors.darkSurface,
        onSurface: AppColors.textOnDark,
        error: AppColors.error,
        onError: AppColors.textOnDark,
        outline: AppColors.darkBorder,
      );

  static TextTheme _textTheme(Color base) => GoogleFonts.interTextTheme(
        TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            color: base,
            letterSpacing: -1.5,
          ),
          displayMedium: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            color: base,
            letterSpacing: -0.5,
          ),
          displaySmall: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: base,
          ),
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: base,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: base,
          ),
          headlineSmall: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: base,
          ),
          titleLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: base,
          ),
          titleMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: base,
          ),
          titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: base,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: base,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: base,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: base,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: base,
            letterSpacing: 0.1,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: base,
            letterSpacing: 0.5,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: base,
            letterSpacing: 0.5,
          ),
        ),
      );

  static AppBarTheme _appBarTheme({
    required Color background,
    required Color foreground,
  }) =>
      AppBarTheme(
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      );

  static CardThemeData _cardTheme(Color color) => CardThemeData(
        color: color,
        elevation: AppDimensions.cardElevation,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
      );

  static ElevatedButtonThemeData _elevatedButtonTheme() =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnDark,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      );

  static OutlinedButtonThemeData _outlinedButtonTheme({bool dark = false}) =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: dark ? AppColors.textOnDark : AppColors.primary,
          minimumSize: const Size(double.infinity, AppDimensions.buttonHeight),
          side: BorderSide(
            color: dark ? AppColors.darkBorder : AppColors.border,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static TextButtonThemeData _textButtonTheme() => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  static InputDecorationTheme _inputDecorationTheme({bool dark = false}) =>
      InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceLG,
          vertical: AppDimensions.spaceMD,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide(
            color: dark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: BorderSide(
            color: dark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textHint,
        ),
        labelStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
        errorStyle: GoogleFonts.inter(
          fontSize: 12,
          color: AppColors.error,
        ),
      );

  static ChipThemeData _chipTheme({bool dark = false}) => ChipThemeData(
        backgroundColor:
            dark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant,
        selectedColor: AppColors.primary,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spaceMD,
          vertical: AppDimensions.spaceXS,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          side: BorderSide(
            color: dark ? AppColors.darkBorder : AppColors.border,
          ),
        ),
      );

  static BottomNavigationBarThemeData _bottomNavTheme({bool dark = false}) =>
      BottomNavigationBarThemeData(
        backgroundColor: dark ? AppColors.darkSurface : AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textHint,
        selectedLabelStyle:
            GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w400),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      );

  static DialogThemeData _dialogTheme(Color background) => DialogThemeData(
        backgroundColor: background,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        ),
      );

  static SnackBarThemeData _snackBarTheme({bool dark = false}) =>
      SnackBarThemeData(
        backgroundColor:
            dark ? AppColors.darkSurfaceVariant : AppColors.primary,
        contentTextStyle: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textOnDark,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
      );

  static SwitchThemeData _switchTheme() => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.textHint;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withOpacity(0.3);
          }
          return AppColors.border;
        }),
      );

  static CheckboxThemeData _checkboxTheme() => CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.textOnDark),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXS),
        ),
        side: const BorderSide(color: AppColors.border, width: 1.5),
      );
}

/// Custom theme extension for extra design tokens
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.cardBorder,
    required this.subtleBackground,
    required this.sidebarBackground,
    required this.badgeResident,
    required this.badgeSecurity,
    required this.badgeAdmin,
  });

  final Color cardBorder;
  final Color subtleBackground;
  final Color sidebarBackground;
  final Color badgeResident;
  final Color badgeSecurity;
  final Color badgeAdmin;

  static const light = AppThemeExtension(
    cardBorder: AppColors.border,
    subtleBackground: AppColors.surfaceVariant,
    sidebarBackground: AppColors.primary,
    badgeResident: AppColors.residentBadge,
    badgeSecurity: AppColors.securityBadge,
    badgeAdmin: AppColors.adminBadge,
  );

  static const dark = AppThemeExtension(
    cardBorder: AppColors.darkBorder,
    subtleBackground: AppColors.darkSurfaceVariant,
    sidebarBackground: AppColors.primaryDark,
    badgeResident: AppColors.residentBadge,
    badgeSecurity: AppColors.securityBadge,
    badgeAdmin: AppColors.adminBadge,
  );

  @override
  AppThemeExtension copyWith({
    Color? cardBorder,
    Color? subtleBackground,
    Color? sidebarBackground,
    Color? badgeResident,
    Color? badgeSecurity,
    Color? badgeAdmin,
  }) =>
      AppThemeExtension(
        cardBorder: cardBorder ?? this.cardBorder,
        subtleBackground: subtleBackground ?? this.subtleBackground,
        sidebarBackground: sidebarBackground ?? this.sidebarBackground,
        badgeResident: badgeResident ?? this.badgeResident,
        badgeSecurity: badgeSecurity ?? this.badgeSecurity,
        badgeAdmin: badgeAdmin ?? this.badgeAdmin,
      );

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      subtleBackground:
          Color.lerp(subtleBackground, other.subtleBackground, t)!,
      sidebarBackground:
          Color.lerp(sidebarBackground, other.sidebarBackground, t)!,
      badgeResident: Color.lerp(badgeResident, other.badgeResident, t)!,
      badgeSecurity: Color.lerp(badgeSecurity, other.badgeSecurity, t)!,
      badgeAdmin: Color.lerp(badgeAdmin, other.badgeAdmin, t)!,
    );
  }
}
