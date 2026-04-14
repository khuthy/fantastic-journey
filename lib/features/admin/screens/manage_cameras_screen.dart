import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../../../features/cameras/models/camera_model.dart';
import '../../../features/cameras/providers/camera_provider.dart';
import '../../../shared/widgets/app_card.dart';

class ManageCamerasScreen extends ConsumerWidget {
  const ManageCamerasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(cameraListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {},
            tooltip: 'Add camera',
          ),
        ],
      ),
      body: camerasAsync.when(
        data: (cameras) {
          if (cameras.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam_off_outlined,
                      size: 64, color: AppColors.textHint),
                  const SizedBox(height: 16),
                  Text('No cameras configured',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          )),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Camera'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(cameraListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppDimensions.spaceLG),
              itemCount: cameras.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppDimensions.spaceSM),
              itemBuilder: (context, i) => _CameraManageTile(
                camera: cameras[i],
                onView: () => context.go(
                  AppRoutes.cameraViewer
                      .replaceFirst(':cameraId', cameras[i].id),
                ),
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _CameraManageTile extends StatelessWidget {
  const _CameraManageTile({required this.camera, required this.onView});
  final CameraModel camera;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (camera.status) {
      CameraStatus.online => AppColors.gateOpen,
      CameraStatus.offline => AppColors.error,
      CameraStatus.maintenance => AppColors.warning,
    };

    return AppCard(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(Icons.videocam_rounded, color: statusColor, size: 24),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(camera.name,
                    style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(camera.location.label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary)),
                    if (camera.ipAddress != null) ...[
                      const Text(' · ',
                          style: TextStyle(color: AppColors.textHint)),
                      Text(camera.ipAddress!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                  color: AppColors.textHint,
                                  fontFamily: 'monospace')),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            ),
            child: Text(
              camera.status.name,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.play_circle_outline_rounded),
            color: AppColors.primary,
            onPressed: onView,
            tooltip: 'View feed',
            iconSize: 22,
          ),
        ],
      ),
    );
  }
}
