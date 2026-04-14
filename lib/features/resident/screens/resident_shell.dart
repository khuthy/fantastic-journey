import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/responsive_layout.dart';

class ResidentShell extends ConsumerWidget {
  const ResidentShell({super.key, required this.child});
  final Widget child;

  static const _destinations = [
    AdaptiveDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    AdaptiveDestination(
      icon: Icons.qr_code_2_outlined,
      selectedIcon: Icons.qr_code_2_rounded,
      label: 'Passes',
    ),
    AdaptiveDestination(
      icon: Icons.add_circle_outline_rounded,
      selectedIcon: Icons.add_circle_rounded,
      label: 'New Pass',
    ),
    AdaptiveDestination(
      icon: Icons.campaign_outlined,
      selectedIcon: Icons.campaign_rounded,
      label: 'News',
    ),
    AdaptiveDestination(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  static const _routes = [
    AppRoutes.residentDashboard,
    AppRoutes.myPasses,
    AppRoutes.createPass,
    AppRoutes.residentAnnouncements,
    AppRoutes.residentProfile,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _routes.indexOf(location);
    return idx < 0 ? 0 : idx;
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
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: AppColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Text('Protea Glen'),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        if (AppHelpers.isMobile(context))
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _Avatar(name: name),
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
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: AppColors.primary,
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
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Resident Portal',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Avatar(name: name, dark: true),
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
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Resident',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                      ),
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
                Icon(Icons.logout_rounded,
                    size: 20, color: Colors.white54),
                SizedBox(width: 12),
                Text(
                  'Sign Out',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.dark = false});
  final String name;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final initials = AppHelpers.initials(name);
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: dark ? AppColors.accent : AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: dark ? AppColors.primary : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
