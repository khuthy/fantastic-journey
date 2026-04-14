import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/helpers.dart';
import '../providers/security_provider.dart';
import '../../../shared/widgets/app_card.dart';

class EntryLogScreen extends ConsumerWidget {
  const EntryLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(recentEntryLogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entry Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () {},
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {},
            tooltip: 'Export',
          ),
        ],
      ),
      body: logAsync.when(
        data: (log) {
          if (log.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text(
                    'No entries recorded',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(recentEntryLogProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              itemCount: log.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.spaceSM),
              itemBuilder: (context, i) => _EntryCard(entry: log[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Error: $e',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry});
  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final success = entry['success'] as bool? ?? true;
    final passType = entry['pass_type'] as String? ?? 'qr';
    final time = entry['created_at'] != null
        ? DateTime.parse(entry['created_at'] as String)
        : null;

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: success ? AppColors.successLight : AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(
              success ? Icons.login_rounded : Icons.block_rounded,
              color: success ? AppColors.success : AppColors.error,
              size: 22,
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
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      entry['resident_unit'] as String? ?? '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (entry['vehicle_registration'] != null) ...[
                      const Text(' · ',
                          style: TextStyle(color: AppColors.textHint)),
                      Text(
                        entry['vehicle_registration'] as String,
                        style:
                            Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                passType == 'otp'
                    ? Icons.pin_rounded
                    : Icons.qr_code_2_rounded,
                size: 14,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 4),
              if (time != null)
                Text(
                  AppHelpers.relativeTime(time),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textHint,
                      ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
