import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/app_card.dart';
import '../providers/security_provider.dart';

class SecurityDashboardScreen extends ConsumerWidget {
  const SecurityDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryLogAsync = ref.watch(recentEntryLogProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(recentEntryLogProvider),
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
                decoration: const BoxDecoration(
                  gradient: AppColors.cardGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _greeting(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Security Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spaceXL),
                    _GateStatusCard(),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats row
                  entryLogAsync.when(
                    data: (log) => Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            title: "Today's Entries",
                            value: log
                                .where((e) {
                                  final d = DateTime.parse(
                                      e['created_at'] as String);
                                  return AppHelpers.formatDate(d) ==
                                      AppHelpers.formatDate(DateTime.now());
                                })
                                .length
                                .toString(),
                            icon: Icons.login_rounded,
                            iconColor: AppColors.success,
                            iconBackground: AppColors.successLight,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spaceMD),
                        Expanded(
                          child: StatCard(
                            title: 'Total Log',
                            value: log.length.toString(),
                            icon: Icons.list_alt_rounded,
                            iconColor: AppColors.info,
                            iconBackground: AppColors.infoLight,
                          ),
                        ),
                      ],
                    ),
                    loading: () => const SizedBox(height: 80),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: AppDimensions.spaceXXL),

                  // Quick actions
                  Row(
                    children: [
                      Expanded(
                        child: _BigActionCard(
                          icon: Icons.qr_code_scanner_rounded,
                          label: 'Scan Visitor Pass',
                          color: AppColors.primary,
                          onTap: () => context.go(AppRoutes.scanPass),
                        ),
                      ),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: _BigActionCard(
                          icon: Icons.videocam_rounded,
                          label: 'Camera Feeds',
                          color: AppColors.securityBadge,
                          onTap: () => context.go(AppRoutes.securityCameras),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceXXL),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Entries',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton(
                        onPressed: () => context.go(AppRoutes.entryLog),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('View all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spaceMD),
                  entryLogAsync.when(
                    data: (log) => log.isEmpty
                        ? AppCard(
                            padding: const EdgeInsets.all(
                                AppDimensions.space3XL),
                            child: const Center(
                              child: Text('No entries recorded yet'),
                            ),
                          )
                        : Column(
                            children: log
                                .take(5)
                                .map((e) => Padding(
                                      padding: const EdgeInsets.only(
                                          bottom: AppDimensions.spaceSM),
                                      child: _EntryTile(entry: e),
                                    ))
                                .toList(),
                          ),
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error: $e'),
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

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning, Officer';
    if (hour < 17) return 'Good afternoon, Officer';
    return 'Good evening, Officer';
  }
}

class _GateStatusCard extends StatelessWidget {
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
              'Main Gate — Open',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          // Gate toggle
          Switch.adaptive(
            value: true,
            onChanged: (_) {},
            activeColor: AppColors.gateOpen,
          ),
        ],
      ),
    );
  }
}

class _BigActionCard extends StatelessWidget {
  const _BigActionCard({
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
      padding: const EdgeInsets.all(AppDimensions.spaceXXL),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusLG),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final success = entry['success'] as bool? ?? true;
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceLG,
        vertical: AppDimensions.spaceMD,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: success ? AppColors.successLight : AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              success ? Icons.check_rounded : Icons.close_rounded,
              color: success ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry['visitor_name'] as String? ?? 'Unknown visitor',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  entry['resident_unit'] as String? ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Text(
            entry['created_at'] != null
                ? AppHelpers.relativeTime(
                    DateTime.parse(entry['created_at'] as String))
                : '',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
        ],
      ),
    );
  }
}
