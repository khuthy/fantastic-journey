import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/resident/screens/resident_shell.dart';
import '../../features/resident/screens/resident_dashboard_screen.dart';
import '../../features/resident/screens/create_pass_screen.dart';
import '../../features/resident/screens/my_passes_screen.dart';
import '../../features/resident/screens/resident_profile_screen.dart';
import '../../features/security/screens/security_shell.dart';
import '../../features/security/screens/security_dashboard_screen.dart';
import '../../features/security/screens/scan_pass_screen.dart';
import '../../features/security/screens/entry_log_screen.dart';
import '../../features/cameras/screens/camera_list_screen.dart';
import '../../features/cameras/screens/camera_viewer_screen.dart';
import '../../features/admin/screens/admin_shell.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/manage_residents_screen.dart';
import '../../features/admin/screens/manage_announcements_screen.dart';
import '../../features/admin/screens/manage_cameras_screen.dart';
import '../../features/announcements/screens/announcements_screen.dart';

// ---------------------------------------------------------------------------
// Route names
// ---------------------------------------------------------------------------

abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';

  // Resident
  static const String residentHome = '/resident';
  static const String residentDashboard = '/resident/dashboard';
  static const String createPass = '/resident/create-pass';
  static const String myPasses = '/resident/passes';
  static const String residentAnnouncements = '/resident/announcements';
  static const String residentProfile = '/resident/profile';

  // Security
  static const String securityHome = '/security';
  static const String securityDashboard = '/security/dashboard';
  static const String scanPass = '/security/scan';
  static const String entryLog = '/security/entry-log';
  static const String securityCameras = '/security/cameras';
  static const String cameraViewer = '/security/cameras/:cameraId';

  // Admin
  static const String adminHome = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String manageResidents = '/admin/residents';
  static const String manageAnnouncements = '/admin/announcements';
  static const String manageCameras = '/admin/cameras';
  static const String adminEntryLog = '/admin/entry-log';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuth = authState is AuthAuthenticated;
      final isLoading = authState is AuthInitial || authState is AuthLoading;
      final path = state.matchedLocation;

      // Let splash handle initial loading
      if (path == AppRoutes.splash) return null;

      // If not authenticated, only allow auth pages
      if (!isAuth && !isLoading) {
        if (path == AppRoutes.login || path == AppRoutes.register) return null;
        return AppRoutes.login;
      }

      // If authenticated, redirect away from auth pages
      if (isAuth) {
        if (path == AppRoutes.login || path == AppRoutes.register) {
          return _homeForRole(authState.user.role);
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (_, __) => const RegisterScreen(),
      ),

      // ---- Resident shell ----
      ShellRoute(
        builder: (_, __, child) => ResidentShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.residentDashboard,
            builder: (_, __) => const ResidentDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.createPass,
            builder: (_, __) => const CreatePassScreen(),
          ),
          GoRoute(
            path: AppRoutes.myPasses,
            builder: (_, __) => const MyPassesScreen(),
          ),
          GoRoute(
            path: AppRoutes.residentAnnouncements,
            builder: (_, __) => const AnnouncementsScreen(),
          ),
          GoRoute(
            path: AppRoutes.residentProfile,
            builder: (_, __) => const ResidentProfileScreen(),
          ),
        ],
      ),

      // ---- Security shell ----
      ShellRoute(
        builder: (_, __, child) => SecurityShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.securityDashboard,
            builder: (_, __) => const SecurityDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.scanPass,
            builder: (_, __) => const ScanPassScreen(),
          ),
          GoRoute(
            path: AppRoutes.entryLog,
            builder: (_, __) => const EntryLogScreen(),
          ),
          GoRoute(
            path: AppRoutes.securityCameras,
            builder: (_, __) => const CameraListScreen(),
          ),
          GoRoute(
            path: AppRoutes.cameraViewer,
            builder: (context, state) => CameraViewerScreen(
              cameraId: state.pathParameters['cameraId']!,
            ),
          ),
        ],
      ),

      // ---- Admin shell ----
      ShellRoute(
        builder: (_, __, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.adminDashboard,
            builder: (_, __) => const AdminDashboardScreen(),
          ),
          GoRoute(
            path: AppRoutes.manageResidents,
            builder: (_, __) => const ManageResidentsScreen(),
          ),
          GoRoute(
            path: AppRoutes.manageAnnouncements,
            builder: (_, __) => const ManageAnnouncementsScreen(),
          ),
          GoRoute(
            path: AppRoutes.manageCameras,
            builder: (_, __) => const ManageCamerasScreen(),
          ),
          GoRoute(
            path: AppRoutes.adminEntryLog,
            builder: (_, __) => const EntryLogScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => _ErrorPage(error: state.error),
  );
});

String _homeForRole(UserRole role) {
  switch (role) {
    case UserRole.security:
      return AppRoutes.securityDashboard;
    case UserRole.admin:
      return AppRoutes.adminDashboard;
    case UserRole.resident:
      return AppRoutes.residentDashboard;
  }
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Text('Page not found\n${error?.toString() ?? ''}'),
        ),
      );
}
