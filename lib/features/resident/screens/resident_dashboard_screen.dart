import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../providers/resident_provider.dart';

class ResidentDashboardScreen extends ConsumerWidget {
  const ResidentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final passesAsync = ref.watch(recentPassesProvider);
    final announcementsAsync = ref.watch(recentAnnouncementsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(recentPassesProvider);
          ref.invalidate(recentAnnouncementsProvider);
        },
        child: CustomScrollView(
          slivers: [
            _buildHeroSliver(context, user?.fullName ?? 'Resident'),
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _QuickActions(),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  _SectionHeader(
                    title: 'Recent Visitor Passes',
                    actionLabel: 'View all',
                    onAction: () => context.go(AppRoutes.myPasses),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  passesAsync.when(
                    data: (passes) => passes.isEmpty
                        ? _EmptyState(
                            icon: Icons.qr_code_2_outlined,
                            message: 'No visitor passes yet',
                            action: 'Create Pass',
                            onAction: () => context.go(AppRoutes.createPass),
                          )
                        : Column(
                            children: passes
                                .take(3)
                                .map((p) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: AppDimensions.spaceMD),
                                      child: _PassTile(pass: p),
                                    ))
                                .toList(),
                          ),
                    loading: () => _PassListSkeleton(),
                    error: (e, _) => _ErrorState(message: e.toString()),
                  ),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  _SectionHeader(
                    title: 'Announcements',
                    actionLabel: 'View all',
                    onAction: () => context.go(AppRoutes.residentAnnouncements),
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  announcementsAsync.when(
                    data: (items) => items.isEmpty
                        ? _EmptyState(
                            icon: Icons.campaign_outlined,
                            message: 'No announcements',
                          )
                        : Column(
                            children: items
                                .take(2)
                                .map((a) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: AppDimensions.spaceMD),
                                      child: _AnnouncementTile(item: a),
                                    ))
                                .toList(),
                          ),
                    loading: () => _AnnouncementSkeleton(),
                    error: (e, _) => _ErrorState(message: e.toString()),
                  ),
                  const SizedBox(height: AppDimensions.space4XL),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSliver(BuildContext context, String name) {
    final greeting = _greeting();
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.spaceLG,
          AppDimensions.spaceXL,
          AppDimensions.spaceLG,
          AppDimensions.space3XL,
        ),
        decoration: const BoxDecoration(
          gradient: AppColors.cardGradient,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$greeting,',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              name.split(' ').first,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppDimensions.spaceXL),
            _StatusBanner(),
          ],
        ),
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _StatusBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spaceMD),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: AppColors.gateOpen,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Main gate is open — guard on duty',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppDimensions.spaceMD),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.add_circle_rounded,
                label: 'Create\nVisitor Pass',
                color: AppColors.primary,
                onTap: () => context.go(AppRoutes.createPass),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceMD),
            Expanded(
              child: _ActionCard(
                icon: Icons.qr_code_rounded,
                label: 'My Active\nPasses',
                color: AppColors.info,
                onTap: () => context.go(AppRoutes.myPasses),
              ),
            ),
            const SizedBox(width: AppDimensions.spaceMD),
            Expanded(
              child: _ActionCard(
                icon: Icons.person_rounded,
                label: 'My\nProfile',
                color: AppColors.residentBadge,
                onTap: () => context.go(AppRoutes.residentProfile),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _PassTile extends StatelessWidget {
  const _PassTile({required this.pass});
  final Map<String, dynamic> pass;

  @override
  Widget build(BuildContext context) {
    final isActive = pass['status'] == 'active';
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.successLight
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(
              pass['pass_type'] == 'otp'
                  ? Icons.pin_outlined
                  : Icons.qr_code_2_rounded,
              color: isActive ? AppColors.success : AppColors.textHint,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pass['visitor_name'] as String? ?? 'Visitor',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  AppHelpers.expiryLabel(
                    DateTime.parse(pass['expires_at'] as String),
                  ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isActive ? AppColors.successLight : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              isActive ? 'Active' : (pass['status'] as String? ?? 'Unknown'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isActive ? AppColors.success : AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final priority = item['priority'] as String? ?? 'medium';
    final isUrgent = priority == 'urgent' || priority == 'high';

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      borderColor: isUrgent ? AppColors.warning.withOpacity(0.4) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isUrgent)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: AppColors.warning,
                    size: 16,
                  ),
                ),
              Expanded(
                child: Text(
                  item['title'] as String? ?? '',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item['body'] as String? ?? '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            AppHelpers.relativeTime(
              DateTime.parse(item['created_at'] as String),
            ),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.space3XL),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: AppColors.textHint, size: 40),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (action != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      borderColor: AppColors.error.withOpacity(0.3),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Failed to load: $message',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _PassListSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
          child: AppCard(
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                ),
                const SizedBox(width: AppDimensions.spaceMD),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 13, width: 120, color: AppColors.border),
                      const SizedBox(height: 6),
                      Container(height: 11, width: 80, color: AppColors.border),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spaceMD),
          child: AppCard(
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, width: 200, color: AppColors.border),
                const SizedBox(height: 8),
                Container(height: 11, width: double.infinity, color: AppColors.border),
                const SizedBox(height: 4),
                Container(height: 11, width: 180, color: AppColors.border),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
