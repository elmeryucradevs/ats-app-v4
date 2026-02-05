import 'package:atesur_app_v4/src/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/full_video_player.dart';
import '../widgets/program_guide_widget.dart';
import '../providers/pip_provider.dart';
import '../providers/video_player_provider.dart';
import '../../schedule/models/program_model.dart'; // Usar modelo unificado
import '../../schedule/providers/schedule_provider.dart' as schedule_providers;
import '../services/chromecast_service.dart';
import '../../../core/services/platform_service.dart'; // Detected via tool
import '../providers/tv_fullscreen_provider.dart';
import '../../shell/providers/menu_focus_provider.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/appbar_logo_widget.dart';
import '../../advertising/widgets/smart_banner.dart';
import '../../advertising/models/ad_entities.dart';

/// Pantalla principal del reproductor de video en vivo
///
/// Muestra el reproductor de video HLS con la guía de programación debajo.
/// Incluye indicador del programa actualmente en vivo.
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  void _toggleTvFullscreen() {
    ref.read(tvFullscreenProvider.notifier).toggle();
  }

  @override
  Widget build(BuildContext context) {
    final currentProgramAsync = ref.watch(currentProgramProvider);

    // Activar suscripción Realtime
    ref.watch(schedule_providers.scheduleRealtimeProvider);

    // Check PiP mode from global provider
    final isPipMode = ref.watch(pipProvider);

    // Check TV Fullscreen mode (global)
    final isTvFullscreen = ref.watch(tvFullscreenProvider);

    // Check TV Mode
    final isTvDetected = ref.watch(isTvProvider);
    final isTv =
        MediaQuery.of(context).navigationMode == NavigationMode.directional ||
            isTvDetected;

    // Handle Back button to exit TV fullscreen or focus menu
    return PopScope(
      canPop: !isTvFullscreen && !isTv,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        if (isTvFullscreen) {
          _toggleTvFullscreen();
        } else if (isTv) {
          // Si estamos en modo normal TV, el botón Back enfoca el menú
          ref.read(menuFocusControllerProvider.notifier).requestFocus();
        }
      },
      child: Scaffold(
        appBar: (isPipMode || isTvFullscreen)
            ? null // Hide AppBar in PiP mode or TV Fullscreen
            : AppBar(
                title: AppBarLogoWidget(
                  height: 32,
                  fallbackText:
                      isTv ? 'ATESUR - EN VIVO (TV)' : 'ATESUR - EN VIVO',
                ),
                actions: [
                  // TV Fullscreen Button (solo en TV)
                  if (isTv)
                    TVIconButton(
                      id: 'player_fullscreen',
                      icon: const Icon(Icons.fullscreen),
                      tooltip: 'Pantalla Completa',
                      leftId: 'nav_0', // Volver al sidebar
                      downId: 'guide_program_0', // Ir a guía de programación
                      onPressed: _toggleTvFullscreen,
                    ),
                  // Botón PiP (NO mostrar en TV ni Web)
                  if (!isTv && !kIsWeb)
                    TVIconButton(
                      id: 'player_pip',
                      icon: const Icon(Icons.picture_in_picture_alt),
                      tooltip: 'Picture in Picture',
                      leftId: 'nav_0',
                      rightId: 'player_cast',
                      downId: 'guide_program_0',
                      onPressed: () async {
                        // Use provider notifier to trigger PiP
                        ref.read(pipProvider.notifier).enterPipMode();
                      },
                    ),
                  // Botón de Chromecast (NO mostrar en TV)
                  if (!isTv)
                    TVIconButton(
                      id: 'player_cast',
                      icon: const Icon(Icons.cast),
                      tooltip: 'Chromecast',
                      leftId: 'player_pip',
                      downId: 'guide_program_0',
                      onPressed: () {
                        ChromecastService().openDeviceSelector(context);
                      },
                    ),
                ],
              ),
        body: OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            if (isPipMode || isTvFullscreen) {
              // En TV Fullscreen, el video debe llenar toda la pantalla
              return SizedBox.expand(
                child: FullVideoPlayer(isPipMode: isPipMode),
              );
            }

            // Desktop/TV usually reports landscape, treat as such
            // but we want side-by-side only if enough width
            final isWide =
                MediaQuery.of(context).size.width >= 600 || isLandscape;

            // WEB: Layout vertical (video arriba, guía abajo)
            if (kIsWeb) {
              return Column(
                children: [
                  // Reproductor más grande (60% del alto)
                  Expanded(
                    flex: 3,
                    child: FullVideoPlayer(isPipMode: isPipMode),
                  ),
                  // Banner de programa actual
                  _buildCurrentProgramBanner(context, ref, currentProgramAsync),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: SmartBanner(position: AdPosition.center),
                  ),
                  const Divider(height: 1),
                  // Guía de programación más pequeña (40% del alto)
                  const Expanded(
                    flex: 2,
                    child: ProgramGuideWidget(),
                  ),
                ],
              );
            }

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Video Section (Left / Main)
                  Expanded(
                    flex: 3, // 60%
                    child: FocusTraversalGroup(
                      // Agrupar foco del contenido principal
                      child: Column(
                        children: [
                          // Video takes available space with AspectRatio
                          Expanded(
                            child: Center(
                              child: FullVideoPlayer(isPipMode: isPipMode),
                            ),
                          ),
                          // Current Program Banner below video (fixed height)
                          _buildCurrentProgramBanner(
                              context, ref, currentProgramAsync),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Guide Section (Right / Side)
                  const Expanded(
                    flex: 2, // 40%
                    child: ProgramGuideWidget(),
                  ),
                ],
              );
            }

            // Portrait Mode (Mobile)
            return Column(
              children: [
                // Reproductor de video
                FullVideoPlayer(isPipMode: isPipMode),

                // Indicador de programa actual
                _buildCurrentProgramBanner(context, ref, currentProgramAsync),

                const SizedBox(height: 8),
                const SmartBanner(position: AdPosition.center), // Banner móvil
                const Divider(height: 1),

                // Guía de programación
                const Expanded(child: ProgramGuideWidget()),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Banner que muestra el programa actualmente en vivo
  Widget _buildCurrentProgramBanner(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<Program?> currentProgramAsync,
  ) {
    return currentProgramAsync.when(
      data: (program) {
        if (program == null) {
          return _buildNoProgramBanner(context);
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              bottom: BorderSide(
                color: AppTheme.liveIndicatorColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              // Indicador EN VIVO pulsante
              _buildPulsingLiveIndicator(),

              const SizedBox(width: AppConstants.spacingMd),

              // Información del programa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppConstants.spacingXs),
                    Text(
                      '${program.timeRange} • ${program.durationInMinutes} min',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppConstants.spacingMd),
            Text('Cargando programación...'),
          ],
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildNoProgramBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingSm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppTheme.liveIndicatorColor,
              borderRadius: BorderRadius.circular(AppConstants.radiusXs),
            ),
            child: const Text(
              'EN VIVO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppConstants.spacingMd),
          Expanded(
            child: Text(
              'Transmisión en vivo de ATESUR',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  /// Indicador EN VIVO con animación pulsante
  Widget _buildPulsingLiveIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.spacingSm,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: AppTheme.liveIndicatorColor,
            borderRadius: BorderRadius.circular(AppConstants.radiusXs),
            boxShadow: [
              BoxShadow(
                color: AppTheme.liveIndicatorColor.withValues(
                  alpha: value * 0.5,
                ),
                blurRadius: 8 * value,
                spreadRadius: 2 * value,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5 + (value * 0.5)),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'EN VIVO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      },
      onEnd: () {
        // La animación se repetirá automáticamente
      },
    );
  }
}
