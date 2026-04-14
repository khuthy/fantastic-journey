import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/helpers.dart';
import '../providers/admin_provider.dart';
import '../../../shared/widgets/app_card.dart';

class ManageResidentsScreen extends ConsumerStatefulWidget {
  const ManageResidentsScreen({super.key});

  @override
  ConsumerState<ManageResidentsScreen> createState() =>
      _ManageResidentsScreenState();
}

class _ManageResidentsScreenState
    extends ConsumerState<ManageResidentsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final residentsAsync = ref.watch(allResidentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Residents'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spaceLG,
              0,
              AppDimensions.spaceLG,
              AppDimensions.spaceMD,
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, unit or email...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
            ),
          ),
        ),
      ),
      body: residentsAsync.when(
        data: (all) {
          final filtered = _query.isEmpty
              ? all
              : all.where((r) {
                  return (r['full_name'] as String? ?? '')
                          .toLowerCase()
                          .contains(_query) ||
                      (r['unit_number'] as String? ?? '')
                          .toLowerCase()
                          .contains(_query) ||
                      (r['email'] as String? ?? '')
                          .toLowerCase()
                          .contains(_query);
                }).toList();

          if (filtered.isEmpty) {
            return Center(
              child: Text('No residents found',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      )),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allResidentsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.spaceSM),
              itemBuilder: (context, i) =>
                  _ResidentTile(resident: filtered[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ResidentTile extends StatelessWidget {
  const _ResidentTile({required this.resident});
  final Map<String, dynamic> resident;

  @override
  Widget build(BuildContext context) {
    final name = resident['full_name'] as String? ?? '';
    final isVerified = resident['is_verified'] as bool? ?? false;
    final isActive = resident['is_active'] as bool? ?? true;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.residentBadge.withOpacity(0.1)
                  : AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                AppHelpers.initials(name),
                style: TextStyle(
                  color: isActive
                      ? AppColors.residentBadge
                      : AppColors.textHint,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: Theme.of(context).textTheme.titleSmall),
                    if (isVerified) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.verified_rounded,
                          color: AppColors.info, size: 14),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Unit ${resident['unit_number'] ?? ''} · ${resident['phone'] ?? ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded,
                color: AppColors.textHint, size: 20),
            itemBuilder: (_) => [
              if (!isVerified)
                const PopupMenuItem(
                  value: 'verify',
                  child: Row(children: [
                    Icon(Icons.verified_rounded,
                        size: 18, color: AppColors.success),
                    SizedBox(width: 8),
                    Text('Approve Account'),
                  ]),
                ),
              PopupMenuItem(
                value: isActive ? 'deactivate' : 'activate',
                child: Row(children: [
                  Icon(
                    isActive
                        ? Icons.block_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: isActive ? AppColors.error : AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(isActive ? 'Deactivate' : 'Activate'),
                ]),
              ),
              const PopupMenuItem(
                value: 'view',
                child: Row(children: [
                  Icon(Icons.visibility_outlined,
                      size: 18, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text('View Details'),
                ]),
              ),
            ],
            onSelected: (action) {
              // TODO: connect to admin repository actions
            },
          ),
        ],
      ),
    );
  }
}
