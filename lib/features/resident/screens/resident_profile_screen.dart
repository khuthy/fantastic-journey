import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';

class ResidentProfileScreen extends ConsumerWidget {
  const ResidentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.spaceLG),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: AppDimensions.avatarXL,
                  height: AppDimensions.avatarXL,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      AppHelpers.initials(user.fullName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceLG),
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: AppDimensions.spaceXS),
                _RoleBadge(role: user.role.label),
                const SizedBox(height: AppDimensions.spaceXXL),

                // Info
                AppCard(
                  padding: const EdgeInsets.all(AppDimensions.spaceXXL),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppDimensions.spaceLG),
                      _Field(icon: Icons.email_outlined, label: 'Email', value: user.email),
                      _Divider(),
                      _Field(icon: Icons.phone_outlined, label: 'Phone', value: AppHelpers.maskPhone(user.phone)),
                      _Divider(),
                      _Field(icon: Icons.home_outlined, label: 'Unit Number', value: user.unitNumber),
                      if (user.vehicleRegistration != null) ...[
                        _Divider(),
                        _Field(
                          icon: Icons.directions_car_outlined,
                          label: 'Vehicle',
                          value: user.vehicleRegistration!,
                        ),
                      ],
                      _Divider(),
                      _Field(
                        icon: Icons.calendar_today_outlined,
                        label: 'Member since',
                        value: AppHelpers.formatDate(user.createdAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.spaceXXL),

                // Account status
                AppCard(
                  padding: const EdgeInsets.all(AppDimensions.spaceXXL),
                  child: Row(
                    children: [
                      Icon(
                        user.isVerified
                            ? Icons.verified_user_rounded
                            : Icons.pending_rounded,
                        color: user.isVerified
                            ? AppColors.success
                            : AppColors.warning,
                        size: 24,
                      ),
                      const SizedBox(width: AppDimensions.spaceMD),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.isVerified
                                  ? 'Account Verified'
                                  : 'Pending Verification',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              user.isVerified
                                  ? 'Your account has been approved by the estate admin.'
                                  : 'Awaiting admin approval.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDimensions.space3XL),
                AppButton(
                  label: 'Sign Out',
                  variant: AppButtonVariant.outlined,
                  leadingIcon: Icons.logout_rounded,
                  onPressed: () =>
                      ref.read(authProvider.notifier).signOut(),
                ),
                const SizedBox(height: AppDimensions.space3XL),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.residentBadge.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
        border: Border.all(
          color: AppColors.residentBadge.withOpacity(0.3),
        ),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: AppColors.residentBadge,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textHint),
        const SizedBox(width: AppDimensions.spaceMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textHint,
                    ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Divider(height: 1),
      );
}
