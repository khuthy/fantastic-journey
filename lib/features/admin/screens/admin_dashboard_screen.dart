import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_card.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.spaceLG,
                  AppDimensions.spaceXXL,
                  AppDimensions.spaceLG,
                  AppDimensions.spaceXXL,
                ),
                decoration: const BoxDecoration(gradient: AppColors.cardGradient),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Admin Dashboard',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Protea Glen Estate Management',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  statsAsync.when(
                    data: (stats) => _StatsGrid(stats: stats),
                    loading: () => const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppDimensions.spaceXXL),
                  Text(
                    'Quick Management',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  _ManagementGrid(),
                  const SizedBox(height: AppDimensions.space4XL),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final Map<String, dynamic> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 600 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        crossAxisSpacing: AppDimensions.spaceMD,
        mainAxisSpacing: AppDimensions.spaceMD,
        childAspectRatio: 1.4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          StatCard(
            title: 'Total Residents',
            value: '${stats['total_residents'] ?? 0}',
            icon: Icons.people_rounded,
            iconColor: AppColors.residentBadge,
            iconBackground: AppColors.residentBadge.withOpacity(0.1),
          ),
          StatCard(
            title: 'Active Passes',
            value: '${stats['active_passes'] ?? 0}',
            icon: Icons.qr_code_2_rounded,
            iconColor: AppColors.success,
            iconBackground: AppColors.successLight,
          ),
          StatCard(
            title: "Today's Entries",
            value: '${stats['today_entries'] ?? 0}',
            icon: Icons.login_rounded,
            iconColor: AppColors.info,
            iconBackground: AppColors.infoLight,
          ),
          StatCard(
            title: 'Cameras Online',
            value: '${stats['cameras_online'] ?? 0}/${stats['total_cameras'] ?? 0}',
            icon: Icons.videocam_rounded,
            iconColor: AppColors.securityBadge,
            iconBackground: AppColors.securityBadge.withOpacity(0.1),
          ),
        ],
      );
    });
  }
}

class _ManagementGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      _ManageItem(
        icon: Icons.people_rounded,
        title: 'Manage Residents',
        subtitle: 'View, approve, and manage accounts',
        color: AppColors.residentBadge,
        route: AppRoutes.manageResidents,
      ),
      _ManageItem(
        icon: Icons.campaign_rounded,
        title: 'Announcements',
        subtitle: 'Post alerts and community news',
        color: AppColors.warning,
        route: AppRoutes.manageAnnouncements,
      ),
      _ManageItem(
        icon: Icons.videocam_rounded,
        title: 'Camera Management',
        subtitle: 'Configure and monitor cameras',
        color: AppColors.securityBadge,
        route: AppRoutes.manageCameras,
      ),
      _ManageItem(
        icon: Icons.list_alt_rounded,
        title: 'Entry Log',
        subtitle: 'Full gate access history',
        color: AppColors.info,
        route: AppRoutes.adminEntryLog,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 2 : 1,
        crossAxisSpacing: AppDimensions.spaceMD,
        mainAxisSpacing: AppDimensions.spaceMD,
        childAspectRatio: 3,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _ManageCard(item: items[i]),
    );
  }
}

class _ManageItem {
  const _ManageItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
}

class _ManageCard extends StatelessWidget {
  const _ManageCard({required this.item});
  final _ManageItem item;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go(item.route),
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(width: AppDimensions.spaceLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(item.title,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(item.subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: AppColors.textHint, size: 20),
        ],
      ),
    );
  }
}
