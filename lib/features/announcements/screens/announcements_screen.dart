import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/helpers.dart';
import '../models/announcement_model.dart';
import '../providers/announcements_provider.dart';
import '../../../shared/widgets/app_card.dart';

class AnnouncementsScreen extends ConsumerWidget {
  const AnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      body: announcementsAsync.when(
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.campaign_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'No announcements',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(announcementsListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.spaceMD),
              itemBuilder: (context, i) =>
                  _AnnouncementCard(announcement: items[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});
  final AnnouncementModel announcement;

  static const _priorityConfig = {
    AnnouncementPriority.urgent: (
      color: AppColors.error,
      bg: AppColors.errorLight,
      icon: Icons.warning_amber_rounded,
    ),
    AnnouncementPriority.high: (
      color: AppColors.warning,
      bg: AppColors.warningLight,
      icon: Icons.priority_high_rounded,
    ),
    AnnouncementPriority.medium: (
      color: AppColors.info,
      bg: AppColors.infoLight,
      icon: Icons.campaign_rounded,
    ),
    AnnouncementPriority.low: (
      color: AppColors.textSecondary,
      bg: AppColors.surfaceVariant,
      icon: Icons.info_outline_rounded,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = _priorityConfig[announcement.priority]!;

    return AppCard(
      borderColor: announcement.priority == AnnouncementPriority.urgent
          ? AppColors.error.withOpacity(0.3)
          : null,
      padding: const EdgeInsets.all(AppDimensions.spaceXXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: config.bg,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSM),
                ),
                child: Icon(config.icon, color: config.color, size: 16),
              ),
              const SizedBox(width: AppDimensions.spaceMD),
              Expanded(
                child: Text(
                  announcement.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (announcement.isPinned)
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Icon(
                    Icons.push_pin_rounded,
                    size: 14,
                    color: AppColors.textHint,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            announcement.body,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          if (announcement.imageUrl != null) ...[
            const SizedBox(height: AppDimensions.spaceMD),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
              child: Image.network(
                announcement.imageUrl!,
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
          const SizedBox(height: AppDimensions.spaceMD),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                announcement.authorName,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                AppHelpers.relativeTime(announcement.createdAt),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
