import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

enum AppButtonVariant { primary, secondary, outlined, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.variant = AppButtonVariant.primary,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = true,
    this.height = AppDimensions.buttonHeight,
    this.borderRadius = AppDimensions.radiusMD,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool fullWidth;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _loaderColor,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(leadingIcon, size: AppDimensions.iconSM),
                const SizedBox(width: 8),
              ],
              Text(label),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: AppDimensions.iconSM),
              ],
            ],
          );

    final style = _resolveStyle(context);

    Widget button;
    switch (variant) {
      case AppButtonVariant.outlined:
      case AppButtonVariant.ghost:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
      default:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: style,
          child: child,
        );
    }

    if (!fullWidth) return button;
    return SizedBox(width: double.infinity, height: height, child: button);
  }

  Color get _loaderColor {
    switch (variant) {
      case AppButtonVariant.primary:
        return Colors.white;
      case AppButtonVariant.secondary:
        return AppColors.primary;
      case AppButtonVariant.danger:
        return Colors.white;
      default:
        return AppColors.primary;
    }
  }

  ButtonStyle _resolveStyle(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
    );

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, height),
          shape: shape,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        );
      case AppButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textOnAccent,
          minimumSize: Size(double.infinity, height),
          shape: shape,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        );
      case AppButtonVariant.outlined:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: Size(double.infinity, height),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: shape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        );
      case AppButtonVariant.ghost:
        return OutlinedButton.styleFrom(
          foregroundColor: AppColors.textSecondary,
          minimumSize: Size(double.infinity, height),
          side: BorderSide.none,
          shape: shape,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        );
      case AppButtonVariant.danger:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, height),
          shape: shape,
          elevation: 0,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        );
    }
  }
}

/// Small icon-only action button
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 40,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor ?? Colors.transparent,
      borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusSM),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              color: color ?? AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}
