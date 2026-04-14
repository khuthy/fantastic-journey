import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/helpers.dart';
import '../models/camera_model.dart';
import '../providers/camera_provider.dart';
import '../../../shared/services/r2_storage_service.dart';
import '../../../shared/widgets/app_card.dart';

class CameraViewerScreen extends ConsumerStatefulWidget {
  const CameraViewerScreen({super.key, required this.cameraId});
  final String cameraId;

  @override
  ConsumerState<CameraViewerScreen> createState() =>
      _CameraViewerScreenState();
}

class _CameraViewerScreenState extends ConsumerState<CameraViewerScreen> {
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _isLoadingStream = true;
  String? _streamError;
  FootageRecord? _selectedFootage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStream());
  }

  Future<void> _loadStream() async {
    final cameras = await ref.read(cameraListProvider.future);
    final camera =
        cameras.firstWhere((c) => c.id == widget.cameraId, orElse: () => cameras.first);

    if (camera.status != CameraStatus.online) {
      setState(() {
        _streamError = 'Camera is ${camera.status.name}';
        _isLoadingStream = false;
      });
      return;
    }

    try {
      await _initPlayer(camera.streamUrl);
    } catch (e) {
      setState(() {
        _streamError = e.toString();
        _isLoadingStream = false;
      });
    }
  }

  Future<void> _loadFootage(FootageRecord footage) async {
    setState(() {
      _selectedFootage = footage;
      _isLoadingStream = true;
      _streamError = null;
    });

    try {
      final r2 = ref.read(r2StorageServiceProvider);
      final url = await r2.getFootageUrl(footage.r2Key);
      await _initPlayer(url);
    } catch (e) {
      setState(() {
        _streamError = e.toString();
        _isLoadingStream = false;
      });
    }
  }

  Future<void> _initPlayer(String url) async {
    _disposePlayer();

    final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
    await ctrl.initialize();

    _chewieCtrl = ChewieController(
      videoPlayerController: ctrl,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      allowFullScreen: true,
      allowMuting: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: AppColors.accent,
        handleColor: AppColors.accent,
        backgroundColor: Colors.white24,
        bufferedColor: Colors.white38,
      ),
    );

    setState(() {
      _videoCtrl = ctrl;
      _isLoadingStream = false;
    });
  }

  void _disposePlayer() {
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    _chewieCtrl = null;
    _videoCtrl = null;
  }

  @override
  void dispose() {
    _disposePlayer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final camerasAsync = ref.watch(cameraListProvider);
    final footageAsync = ref.watch(footageProvider(widget.cameraId));

    return Scaffold(
      appBar: AppBar(
        title: camerasAsync.when(
          data: (cameras) {
            final cam = cameras.firstWhere(
              (c) => c.id == widget.cameraId,
              orElse: () => cameras.first,
            );
            return Text(cam.name);
          },
          loading: () => const Text('Loading...'),
          error: (_, __) => const Text('Camera'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen_rounded),
            onPressed: () {},
            tooltip: 'Fullscreen',
          ),
          IconButton(
            icon: const Icon(Icons.screenshot_outlined),
            onPressed: () {},
            tooltip: 'Screenshot',
          ),
        ],
      ),
      body: Column(
        children: [
          // Video player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPlayer(),
          ),

          // Footage list
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.spaceLG,
                    AppDimensions.spaceXXL,
                    AppDimensions.spaceLG,
                    AppDimensions.spaceMD,
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedFootage == null
                            ? 'Live Feed'
                            : 'Recorded Footage',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_selectedFootage != null) ...[
                        const SizedBox(width: AppDimensions.spaceSM),
                        TextButton(
                          onPressed: _loadStream,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Back to Live'),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: footageAsync.when(
                    data: (footage) => footage.isEmpty
                        ? Center(
                            child: Text(
                              'No footage recorded',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppDimensions.spaceLG,
                            ),
                            itemCount: footage.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppDimensions.spaceSM),
                            itemBuilder: (context, i) =>
                                _FootageTile(
                              record: footage[i],
                              isSelected: _selectedFootage?.id == footage[i].id,
                              onTap: () => _loadFootage(footage[i]),
                            ),
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('$e')),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isLoadingStream) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_streamError != null) {
      return Container(
        color: AppColors.primaryDark,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off_rounded,
                  color: Colors.white24, size: 48),
              const SizedBox(height: 12),
              Text(
                _streamError!,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_chewieCtrl != null) {
      return Chewie(controller: _chewieCtrl!);
    }

    return Container(color: Colors.black);
  }
}

class _FootageTile extends StatelessWidget {
  const _FootageTile({
    required this.record,
    required this.isSelected,
    required this.onTap,
  });

  final FootageRecord record;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      borderColor: isSelected ? AppColors.primary : null,
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spaceLG,
        vertical: AppDimensions.spaceMD,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
            ),
            child: Icon(
              Icons.video_file_rounded,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDimensions.spaceMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppHelpers.formatDateTime(record.startTime),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${AppHelpers.formatFileSize(record.fileSizeBytes)}'
                  '${record.durationSeconds != null ? ' · ${record.durationSeconds}s' : ''}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            isSelected ? Icons.play_circle_rounded : Icons.play_circle_outline_rounded,
            color: isSelected ? AppColors.primary : AppColors.textHint,
            size: 24,
          ),
        ],
      ),
    );
  }
}
