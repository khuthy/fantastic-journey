import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/announcements/models/announcement_model.dart';
import '../../../features/announcements/providers/announcements_provider.dart';
import '../../../shared/services/neon_db_service.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_text_field.dart';

class ManageAnnouncementsScreen extends ConsumerWidget {
  const ManageAnnouncementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final announcementsAsync = ref.watch(announcementsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Announcements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Announcement'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: announcementsAsync.when(
        data: (items) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(announcementsListProvider),
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.campaign_outlined,
                          size: 64, color: AppColors.textHint),
                      const SizedBox(height: 16),
                      Text('No announcements',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spaceLG,
                    AppDimensions.spaceLG,
                    AppDimensions.spaceLG,
                    100,
                  ),
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.spaceMD),
                  itemBuilder: (context, i) =>
                      _AdminAnnouncementTile(item: items[i], ref: ref),
                ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusXXL),
        ),
      ),
      builder: (_) => _CreateAnnouncementSheet(ref: ref),
    );
  }
}

class _AdminAnnouncementTile extends StatelessWidget {
  const _AdminAnnouncementTile({required this.item, required this.ref});
  final AnnouncementModel item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.title,
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded,
                    size: 18, color: AppColors.textHint),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'pin',
                    child: Row(children: [
                      Icon(
                        item.isPinned
                            ? Icons.push_pin_outlined
                            : Icons.push_pin_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(item.isPinned ? 'Unpin' : 'Pin'),
                    ]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_outline_rounded,
                          size: 18, color: AppColors.error),
                      SizedBox(width: 8),
                      Text('Delete',
                          style: TextStyle(color: AppColors.error)),
                    ]),
                  ),
                ],
                onSelected: (action) async {
                  if (action == 'delete') {
                    final confirmed = await _confirmDelete(context);
                    if (confirmed == true) {
                      final db = ref.read(neonDbServiceProvider);
                      await db.deleteAnnouncement(item.id);
                      ref.invalidate(announcementsListProvider);
                    }
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.body,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _PriorityBadge(priority: item.priority),
              const Spacer(),
              Text(
                AppHelpers.relativeTime(item.createdAt),
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Announcement'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  const _PriorityBadge({required this.priority});
  final AnnouncementPriority priority;

  @override
  Widget build(BuildContext context) {
    final (color, bg) = switch (priority) {
      AnnouncementPriority.urgent => (AppColors.error, AppColors.errorLight),
      AnnouncementPriority.high => (AppColors.warning, AppColors.warningLight),
      AnnouncementPriority.medium => (AppColors.info, AppColors.infoLight),
      AnnouncementPriority.low => (AppColors.textSecondary, AppColors.surfaceVariant),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        priority.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CreateAnnouncementSheet extends ConsumerStatefulWidget {
  const _CreateAnnouncementSheet({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_CreateAnnouncementSheet> createState() =>
      _CreateAnnouncementSheetState();
}

class _CreateAnnouncementSheetState
    extends ConsumerState<_CreateAnnouncementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  AnnouncementPriority _priority = AnnouncementPriority.medium;
  bool _isPinned = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final db = ref.read(neonDbServiceProvider);
      await db.createAnnouncement(
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        priority: _priority.label.toLowerCase(),
        isPinned: _isPinned,
      );
      ref.invalidate(announcementsListProvider);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        AppHelpers.showSnackBar(context, e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppDimensions.spaceXXL,
        AppDimensions.spaceXXL,
        AppDimensions.spaceXXL,
        MediaQuery.viewInsetsOf(context).bottom + AppDimensions.spaceXXL,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('New Announcement',
                  style: Theme.of(context).textTheme.headlineSmall),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spaceXXL),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  controller: _titleCtrl,
                  label: 'Title',
                  hint: 'Short, clear heading',
                  prefixIcon: Icons.title_rounded,
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'Title'),
                ),
                const SizedBox(height: AppDimensions.spaceLG),
                AppTextField(
                  controller: _bodyCtrl,
                  label: 'Message',
                  hint: 'Full announcement text...',
                  prefixIcon: Icons.notes_rounded,
                  maxLines: 4,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  validator: (v) => Validators.required(v, 'Message'),
                ),
                const SizedBox(height: AppDimensions.spaceXXL),
                Row(
                  children: [
                    Text('Priority',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(width: AppDimensions.spaceMD),
                    ...AnnouncementPriority.values.map(
                      (p) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(p.label),
                          selected: _priority == p,
                          onSelected: (_) =>
                              setState(() => _priority = p),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: _priority == p ? Colors.white : null,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spaceMD),
                SwitchListTile.adaptive(
                  value: _isPinned,
                  onChanged: (v) => setState(() => _isPinned = v),
                  title: Text('Pin to top',
                      style: Theme.of(context).textTheme.titleSmall),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: AppDimensions.spaceXXL),
                AppButton(
                  label: 'Post Announcement',
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
