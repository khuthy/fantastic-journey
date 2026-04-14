import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.borderRadius = AppDimensions.radiusLG,
    this.elevation = 0,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = color ?? (isDark ? AppColors.darkSurface : AppColors.surface);
    final border =
        borderColor ?? (isDark ? AppColors.darkBorder : AppColors.border);

    Widget card = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: border),
        boxShadow: elevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: elevation * 3,
                  offset: Offset(0, elevation),
                ),
              ]
            : null,
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: card,
        ),
      );
    }
    return card;
  }
}

/// Stat summary card used in dashboards
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
    this.iconBackground,
    this.subtitle,
    this.trend,
    this.trendUp,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackground;
  final String? subtitle;
  final String? trend;
  final bool? trendUp;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final iconBg = iconBackground ?? AppColors.primary.withOpacity(0.1);
    final iconFg = iconColor ?? AppColors.primary;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceXXL),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
                ),
                child: Icon(icon, color: iconFg, size: 22),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.spaceSM,
                    vertical: AppDimensions.spaceXXS,
                  ),
                  decoration: BoxDecoration(
                    color: (trendUp ?? true)
                        ? AppColors.successLight
                        : AppColors.errorLight,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        (trendUp ?? true)
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: (trendUp ?? true)
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: (trendUp ?? true)
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXL),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppDimensions.spaceXXS),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textHint,
                    fontSize: 11,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}
