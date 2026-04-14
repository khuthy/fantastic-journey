import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../core/utils/helpers.dart';
import '../providers/resident_provider.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_button.dart';
import 'pass_display_screen.dart';

class MyPassesScreen extends ConsumerStatefulWidget {
  const MyPassesScreen({super.key});

  @override
  ConsumerState<MyPassesScreen> createState() => _MyPassesScreenState();
}

class _MyPassesScreenState extends ConsumerState<MyPassesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Visitor Passes'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'All Passes'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.createPass),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Pass'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _PassList(activeOnly: true),
          _PassList(activeOnly: false),
        ],
      ),
    );
  }
}

class _PassList extends ConsumerWidget {
  const _PassList({required this.activeOnly});
  final bool activeOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passesAsync = activeOnly
        ? ref.watch(activePassesProvider)
        : ref.watch(recentPassesProvider);

    return passesAsync.when(
      data: (passes) {
        if (passes.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.qr_code_2_outlined,
                  size: 64,
                  color: AppColors.textHint,
                ),
                const SizedBox(height: 16),
                Text(
                  activeOnly ? 'No active passes' : 'No passes yet',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Create a Pass',
                  fullWidth: false,
                  height: AppDimensions.buttonHeightSM,
                  onPressed: () => context.go(AppRoutes.createPass),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activePassesProvider);
            ref.invalidate(recentPassesProvider);
          },
          child: ListView.separated(
            padding: const EdgeInsets.all(AppDimensions.spaceLG),
            itemCount: passes.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppDimensions.spaceMD),
            itemBuilder: (context, i) => _PassCard(pass: passes[i]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('Error: $e',
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _PassCard extends StatelessWidget {
  const _PassCard({required this.pass});
  final Map<String, dynamic> pass;

  bool get _isQr => pass['pass_type'] == 'qr';
  bool get _isActive => pass['status'] == 'active';
  DateTime get _expiresAt => DateTime.parse(pass['expires_at'] as String);

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (pass['status'] as String? ?? '') {
      'active' => AppColors.success,
      'used' => AppColors.info,
      'expired' => AppColors.textHint,
      'revoked' => AppColors.error,
      _ => AppColors.textHint,
    };

    return AppCard(
      borderColor: _isActive ? AppColors.primary.withOpacity(0.2) : null,
      onTap: _isActive
          ? () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => PassDisplayScreen(passData: pass)),
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spaceLG),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isActive
                        ? AppColors.primary.withOpacity(0.1)
                        : AppColors.surfaceVariant,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusMD),
                  ),
                  child: Icon(
                    _isQr
                        ? Icons.qr_code_2_rounded
                        : Icons.pin_rounded,
                    color: _isActive ? AppColors.primary : AppColors.textHint,
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
                        pass['visitor_phone'] as String? ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusFull),
                  ),
                  child: Text(
                    _capitalize(pass['status'] as String? ?? ''),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (pass['vehicle_registration'] != null ||
                pass['purpose'] != null) ...[
              const SizedBox(height: AppDimensions.spaceMD),
              const Divider(height: 1),
              const SizedBox(height: AppDimensions.spaceMD),
              Row(
                children: [
                  if (pass['vehicle_registration'] != null)
                    _Detail(
                      icon: Icons.directions_car_outlined,
                      text: pass['vehicle_registration'] as String,
                    ),
                  if (pass['purpose'] != null)
                    Expanded(
                      child: _Detail(
                        icon: Icons.notes_rounded,
                        text: pass['purpose'] as String,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppDimensions.spaceMD),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      AppHelpers.expiryLabel(_expiresAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textHint,
                          ),
                    ),
                  ],
                ),
                Text(
                  '${pass['use_count'] ?? 0}/${pass['max_uses'] ?? 1} uses',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textHint),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}
