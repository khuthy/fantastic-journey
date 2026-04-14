import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/router/app_router.dart';
import '../models/camera_model.dart';
import '../providers/camera_provider.dart';
import '../../../shared/widgets/app_card.dart';

class CameraListScreen extends ConsumerWidget {
  const CameraListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final camerasAsync = ref.watch(cameraListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Feeds'),
        actions: [
          IconButton(
            icon: const Icon(Icons.grid_view_rounded),
            onPressed: () {},
            tooltip: 'Grid view',
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
                  Text(
                    'No cameras configured',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(cameraListProvider),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.all(AppDimensions.spaceLG),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppDimensions.spaceMD,
                    mainAxisSpacing: AppDimensions.spaceMD,
                    childAspectRatio: 16 / 11,
                  ),
                  itemCount: cameras.length,
                  itemBuilder: (context, i) =>
                      _CameraCard(camera: cameras[i]),
                );
              },
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

class _CameraCard extends StatelessWidget {
  const _CameraCard({required this.camera});
  final CameraModel camera;

  @override
  Widget build(BuildContext context) {
    final isOnline = camera.status == CameraStatus.online;
    final statusColor = switch (camera.status) {
      CameraStatus.online => AppColors.gateOpen,
      CameraStatus.offline => AppColors.error,
      CameraStatus.maintenance => AppColors.warning,
    };

    return AppCard(
      onTap: () => context.go(
        AppRoutes.cameraViewer.replaceFirst(':cameraId', camera.id),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (camera.thumbnailUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppDimensions.radiusLG),
                    ),
                    child: Image.network(
                      camera.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _PlaceholderCamera(),
                    ),
                  )
                else
                  _PlaceholderCamera(),
                // Status indicator
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius:
                          BorderRadius.circular(AppDimensions.radiusFull),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'LIVE' : camera.status.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (camera.isRecording)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.fiber_manual_record,
                              size: 8, color: Colors.white),
                          SizedBox(width: 3),
                          Text(
                            'REC',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppDimensions.spaceMD),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        camera.name,
                        style: Theme.of(context).textTheme.titleSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        camera.location.label,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textHint,
                  size: 18,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderCamera extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary,
      child: const Center(
        child: Icon(
          Icons.videocam_rounded,
          color: Colors.white24,
          size: 48,
        ),
      ),
    );
  }
}
