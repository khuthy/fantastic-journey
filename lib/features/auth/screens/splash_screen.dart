import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0, 0.6)),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(
          parent: _controller, curve: const Interval(0, 0.6, curve: Curves.easeOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next is AuthAuthenticated) {
        final role = next.user.role;
        switch (role) {
          case UserRole.security:
            context.go(AppRoutes.securityDashboard);
          case UserRole.admin:
            context.go(AppRoutes.adminDashboard);
          case UserRole.resident:
            context.go(AppRoutes.residentDashboard);
        }
      } else if (next is AuthUnauthenticated || next is AuthError) {
        context.go(AppRoutes.login);
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryDark],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.security_rounded,
                          color: AppColors.primary,
                          size: 52,
                        ),
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Protea Glen',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Estate Gate Access',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 64),
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: AppColors.accent,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
