import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/responsive_layout.dart';

class SecurityShell extends ConsumerWidget {
  const SecurityShell({super.key, required this.child});
  final Widget child;

  static const _destinations = [
    AdaptiveDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    AdaptiveDestination(
      icon: Icons.qr_code_scanner_outlined,
      selectedIcon: Icons.qr_code_scanner_rounded,
      label: 'Scan',
    ),
    AdaptiveDestination(
      icon: Icons.list_alt_outlined,
      selectedIcon: Icons.list_alt_rounded,
      label: 'Entry Log',
    ),
    AdaptiveDestination(
      icon: Icons.videocam_outlined,
      selectedIcon: Icons.videocam_rounded,
      label: 'Cameras',
    ),
  ];

  static const _routes = [
    AppRoutes.securityDashboard,
    AppRoutes.scanPass,
    AppRoutes.entryLog,
    AppRoutes.securityCameras,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (var i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final idx = _currentIndex(context);

    return AdaptiveScaffold(
      selectedIndex: idx,
      destinations: _destinations,
      onDestinationSelected: (i) => context.go(_routes[i]),
      appBar: _buildAppBar(context, ref, user?.fullName ?? ''),
      sidebarHeader: _buildSidebarHeader(context, user?.fullName ?? ''),
      sidebarFooter: _buildSidebarFooter(context, ref),
      child: child,
    );
  }

  PreferredSizeWidget _buildAppBar(
      BuildContext context, WidgetRef ref, String name) {
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.securityBadge,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Security Portal'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildSidebarHeader(BuildContext context, String name) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.securityBadge,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Protea Glen',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15),
                  ),
                  Text(
                    'Security Portal',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.55), fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(height: 1, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.securityBadge,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    AppHelpers.initials(name),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Security Guard',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarFooter(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(12),
      child: Material(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => ref.read(authProvider.notifier).signOut(),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.logout_rounded, size: 20, color: Colors.white54),
                SizedBox(width: 12),
                Text('Sign Out',
                    style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
