import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'package:atesur_app_v4/src/features/player/widgets/web/mini_web_video_player_stub.dart'
    if (dart.library.js_interop) 'package:atesur_app_v4/src/features/player/widgets/web/mini_web_video_player.dart';

import '../providers/video_player_provider.dart';
import '../../schedule/models/program_model.dart';
import '../../schedule/providers/schedule_provider.dart' as schedule_providers;
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';
import '../../../core/services/platform_service.dart';
import '../../../core/services/config_service.dart';

/// Mini Global Video Player (YouTube Style)
class MiniVideoPlayer extends ConsumerWidget {
  const MiniVideoPlayer({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(videoPlayerProvider);
    final currentProgram = ref.watch(currentProgramProvider);
    final isTv = ref.watch(isTvProvider);

    // Ensure realtime schedule updates
    ref.watch(schedule_providers.scheduleRealtimeProvider);

    // Only show if minimized
    if (!playerState.isMinimized) {
      return const SizedBox.shrink();
    }

    // En modo TV, usar TVCard para el banner completo
    if (isTv) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        child: SizedBox(
          height: AppConstants.miniPlayerHeight,
          child: Row(
            children: [
              // Thumbnail / Video Preview
              _buildThumbnail(ref, playerState),

              // Program Info - TVCard para volver al modo completo
              Expanded(
                child: TVCard(
                  id: 'mini_banner',
                  upId:
                      'content_last', // Conectar con el último elemento del contenido
                  leftId: 'nav_0',
                  rightId: kIsWeb ? 'mini_close' : 'mini_playpause',
                  margin: EdgeInsets.zero,
                  onTap: () {
                    ref.read(videoPlayerProvider.notifier).maximizePlayer();
                    onTap();
                  },
                  child: _buildInfo(context, currentProgram),
                ),
              ),

              // Controls con TVIconButton
              _buildTvControls(context, ref, playerState),
            ],
          ),
        ),
      );
    }

    // Modo normal (no TV) - comportamiento original
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      child: InkWell(
        onTap: () {
          ref.read(videoPlayerProvider.notifier).maximizePlayer();
          onTap();
        },
        child: SizedBox(
          height: AppConstants.miniPlayerHeight,
          child: Row(
            children: [
              // Thumbnail / Video Preview
              _buildThumbnail(ref, playerState),

              // Program Info
              Expanded(child: _buildInfo(context, currentProgram)),

              // Controls
              _buildControls(context, ref, playerState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(WidgetRef ref, VideoPlayerState playerState) {
    // Read the controller from the specific provider
    final videoController = ref.watch(videoControllerProvider);

    return Container(
      width: AppConstants.miniPlayerHeight * (16 / 9),
      height: AppConstants.miniPlayerHeight,
      color: Colors.black,
      child: kIsWeb
          ? ClipRect(
              child: MiniWebVideoPlayer(
                streamUrl: ref.watch(configServiceProvider).streamUrl,
              ),
            )
          : Stack(
              alignment: Alignment.center,
              children: [
                // Real Video Player for Native Apps
                if (videoController != null &&
                    videoController.value.isInitialized)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: VideoPlayer(
                      videoController,
                      key: ValueKey(videoController
                          .dataSource), // Force rebuild on URL change
                    ),
                  )
                else
                  // Placeholder if not initialized
                  const Icon(Icons.video_camera_back, color: Colors.white54),

                // Buffering Indicator
                if (playerState.isBuffering)
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
              ],
            ),
    );
  }

  Widget _buildInfo(BuildContext context, AsyncValue<Program?> programAsync) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppConstants.spacingMd),
      child: programAsync.when(
        data: (program) {
          if (program == null) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ATESUR - EN VIVO',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Transmisión en vivo',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            );
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.liveIndicatorColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'EN VIVO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingSm),
                  Expanded(
                    child: Text(
                      program.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${program.timeRange} • ${program.durationInMinutes} min',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      ),
    );
  }

  /// Controles para modo TV con TVIconButton
  Widget _buildTvControls(
    BuildContext context,
    WidgetRef ref,
    VideoPlayerState playerState,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause Button (Native Only)
        if (!kIsWeb)
          TVIconButton(
            id: 'mini_playpause',
            leftId: 'mini_banner',
            rightId: 'mini_close',
            icon: Icon(
              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            iconSize: AppConstants.iconSizeMd,
            onPressed: () {
              ref.read(videoPlayerProvider.notifier).togglePlayPause();
            },
          ),

        // Close Button
        TVIconButton(
          id: 'mini_close',
          leftId: kIsWeb ? 'mini_banner' : 'mini_playpause',
          icon: const Icon(Icons.close),
          iconSize: AppConstants.iconSizeMd,
          onPressed: () {
            ref.read(videoPlayerProvider.notifier).maximizePlayer();
          },
        ),

        const SizedBox(width: AppConstants.spacingSm),
      ],
    );
  }

  /// Controles normales (no TV)
  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    VideoPlayerState playerState,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause Button (Native Only)
        if (!kIsWeb)
          IconButton(
            icon: Icon(
              playerState.isPlaying ? Icons.pause : Icons.play_arrow,
              size: AppConstants.iconSizeMd,
            ),
            onPressed: () {
              ref.read(videoPlayerProvider.notifier).togglePlayPause();
            },
          ),

        // Close Button
        IconButton(
          icon: const Icon(Icons.close, size: AppConstants.iconSizeMd),
          onPressed: () {
            ref.read(videoPlayerProvider.notifier).maximizePlayer();
          },
        ),

        const SizedBox(width: AppConstants.spacingSm),
      ],
    );
  }
}
