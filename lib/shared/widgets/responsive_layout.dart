import 'package:flutter/material.dart';
import '../../core/constants/app_dimensions.dart';

/// Renders [mobile], [tablet], or [desktop] based on screen width.
/// Falls back to [mobile] if narrower variant is not provided.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppDimensions.mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= AppDimensions.mobileBreakpoint &&
        w < AppDimensions.tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppDimensions.tabletBreakpoint;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppDimensions.tabletBreakpoint) {
          return desktop ?? tablet ?? mobile;
        }
        if (constraints.maxWidth >= AppDimensions.mobileBreakpoint) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}

/// A scaffold that shows a persistent sidebar on desktop and a
/// bottom nav bar on mobile/tablet.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.child,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
    this.appBar,
    this.floatingActionButton,
    this.sidebarHeader,
    this.sidebarFooter,
  });

  final Widget child;
  final int selectedIndex;
  final List<AdaptiveDestination> destinations;
  final ValueChanged<int> onDestinationSelected;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final Widget? sidebarHeader;
  final Widget? sidebarFooter;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppDimensions.tabletBreakpoint) {
          return _DesktopScaffold(this);
        }
        return _MobileScaffold(this);
      },
    );
  }
}

@immutable
class AdaptiveDestination {
  const AdaptiveDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

// ---------------------------------------------------------------------------

class _MobileScaffold extends StatelessWidget {
  const _MobileScaffold(this.parent);
  final AdaptiveScaffold parent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: parent.appBar,
      body: parent.child,
      floatingActionButton: parent.floatingActionButton,
      bottomNavigationBar: _BottomNav(parent: parent),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.parent});
  final AdaptiveScaffold parent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: AppDimensions.bottomNavHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(parent.destinations.length, (i) {
              final dest = parent.destinations[i];
              final isSelected = i == parent.selectedIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => parent.onDestinationSelected(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected ? dest.selectedIcon : dest.icon,
                        size: AppDimensions.iconMD,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        dest.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DesktopScaffold extends StatelessWidget {
  const _DesktopScaffold(this.parent);
  final AdaptiveScaffold parent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(parent: parent),
          Expanded(
            child: Column(
              children: [
                if (parent.appBar != null) parent.appBar!,
                Expanded(child: parent.child),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: parent.floatingActionButton,
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.parent});
  final AdaptiveScaffold parent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: AppDimensions.sidebarWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        border: Border(
          right: BorderSide(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
      ),
      child: Column(
        children: [
          if (parent.sidebarHeader != null) parent.sidebarHeader!,
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              itemCount: parent.destinations.length,
              itemBuilder: (context, i) {
                final dest = parent.destinations[i];
                final isSelected = i == parent.selectedIndex;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => parent.onDestinationSelected(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? dest.selectedIcon : dest.icon,
                              size: 20,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.55),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              dest.label,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white.withOpacity(0.55),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontSize: 14,
                              ),
                            ),
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (parent.sidebarFooter != null) parent.sidebarFooter!,
        ],
      ),
    );
  }
}
