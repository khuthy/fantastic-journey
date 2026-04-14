import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/helpers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    ref.read(authProvider.notifier).signIn(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    ref.listen<AuthState>(authProvider, (_, next) {
      if (next is AuthError) {
        AppHelpers.showSnackBar(context, next.message, isError: true);
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;
            if (isWide) return _DesktopLayout(this);
            return _MobileLayout(this);
          },
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            controller: _emailCtrl,
            label: 'Email address',
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            prefixIcon: Icons.email_outlined,
            validator: Validators.email,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: AppDimensions.spaceLG),
          AppTextField(
            controller: _passwordCtrl,
            label: 'Password',
            hint: '••••••••',
            obscureText: _obscure,
            textInputAction: TextInputAction.done,
            prefixIcon: Icons.lock_outline_rounded,
            onFieldSubmitted: (_) => _submit(),
            validator: (v) =>
                v == null || v.isEmpty ? 'Password is required' : null,
            autofillHints: const [AutofillHints.password],
            suffixIcon: IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXXL),
          AppButton(
            label: 'Sign In',
            isLoading: isLoading,
            onPressed: isLoading ? null : _submit,
          ),
          const SizedBox(height: AppDimensions.spaceLG),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Don't have an account? ",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.register),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Register'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mobile layout
// ---------------------------------------------------------------------------

class _MobileLayout extends StatelessWidget {
  const _MobileLayout(this.state);
  final _LoginScreenState state;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceXXL,
        vertical: AppDimensions.space3XL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppDimensions.space3XL),
          _Logo(),
          const SizedBox(height: AppDimensions.space4XL),
          Text(
            'Welcome back',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: AppDimensions.spaceSM),
          Text(
            'Sign in to your Protea Glen account',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppDimensions.space3XL),
          state._buildForm(context),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Desktop / tablet layout (2-column)
// ---------------------------------------------------------------------------

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout(this.state);
  final _LoginScreenState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left panel — branding
        Expanded(
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.cardGradient,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.space6XL),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space3XL),
                  Text(
                    'Protea Glen\nEstate Access',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: AppDimensions.spaceLG),
                  Text(
                    'Secure, smart gate access management\nfor residents, visitors, and security staff.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.space6XL),
                  _FeaturePill(icon: Icons.qr_code_rounded, label: 'QR & OTP Visitor Passes'),
                  const SizedBox(height: AppDimensions.spaceMD),
                  _FeaturePill(icon: Icons.videocam_rounded, label: 'Live Camera Monitoring'),
                  const SizedBox(height: AppDimensions.spaceMD),
                  _FeaturePill(icon: Icons.campaign_rounded, label: 'Community Announcements'),
                ],
              ),
            ),
          ),
        ),
        // Right panel — form
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.space6XL),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDimensions.space5XL),
                    Text(
                      'Sign in',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: AppDimensions.spaceSM),
                    Text(
                      'Enter your credentials to access the portal.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppDimensions.space3XL),
                    state._buildForm(context),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.security_rounded,
              color: AppColors.accent,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Protea Glen',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'Gate Access',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      );
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
}
