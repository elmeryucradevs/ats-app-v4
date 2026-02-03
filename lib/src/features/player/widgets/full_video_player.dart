import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemChrome for fullscreen
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chewie/chewie.dart';
import '../providers/video_player_provider.dart';
import '../../../core/constants/app_constants.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'web/web_video_player.dart';
import '../services/chromecast_service.dart';
import 'package:video_player/video_player.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';
import '../../../core/services/platform_service.dart';
import '../../../core/services/config_service.dart';
import '../../../core/utils/app_logger.dart'; // AppLogger
import 'tv_video_controls.dart'; // TVVideoControlsBar

///
/// Usa Chewie para proporcionar controles profesionales sobre video_player.
/// Incluye soporte para fullscreen, controles personalizados y manejo de errores.
class FullVideoPlayer extends ConsumerStatefulWidget {
  final bool isPipMode;

  const FullVideoPlayer({super.key, this.isPipMode = false});

  @override
  ConsumerState<FullVideoPlayer> createState() => _FullVideoPlayerState();
}

class _FullVideoPlayerState extends ConsumerState<FullVideoPlayer> {
  ChewieController? _chewieController;
  VideoPlayerController? _cachedVideoController; // Cache for dispose safety
  bool _isCasting = false;
  bool _isFullScreen = false; // Custom fullscreen state

  @override
  void initState() {
    super.initState();
    // Inicializar Chewie después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChewieController();
    });

    // Listen to casting state
    ChromecastService().isConnectedNotifier.addListener(_onCastingStateChanged);
  }

  void _onCastingStateChanged() {
    final isCasting = ChromecastService().isConnectedNotifier.value;
    if (_isCasting != isCasting) {
      setState(() {
        _isCasting = isCasting;
      });

      if (_isCasting) {
        // Pause video when casting starts
        _chewieController?.pause();
      } else {
        // Resume video when casting ends
        _chewieController?.play();
      }
    }
  }

  @override
  void didUpdateWidget(FullVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Force re-init if PiP mode changed to adjust controls
    if (oldWidget.isPipMode != widget.isPipMode) {
      _initializeChewieController();
    }

    // Reinicializar si el controller cambió
    final controller = ref.read(videoControllerProvider);
    if (controller != _chewieController?.videoPlayerController) {
      _initializeChewieController();
    }
  }

  // ===================================
  // CUSTOM FULLSCREEN METHODS
  // ===================================

  void _enterFullScreen() {
    if (_chewieController == null) return;

    setState(() => _isFullScreen = true);

    // Forzar orientación horizontal y ocultar UI del sistema
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    AppLogger.info('[FullVideoPlayer] Entering fullscreen via Navigator.push');

    // Navegar a pantalla fullscreen
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenVideoPage(
            chewieController: _chewieController!,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _exitFullScreen() {
    // Restaurar orientaciones y UI del sistema primero (no require context)
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Solo usar context y setState si el widget sigue montado
    if (mounted) {
      // Cerrar la pantalla fullscreen si está abierta
      if (Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      setState(() => _isFullScreen = false);
    }

    AppLogger.info('[FullVideoPlayer] Exited fullscreen');
  }

  void _toggleFullScreen() {
    if (_isFullScreen) {
      _exitFullScreen();
    } else {
      _enterFullScreen();
    }
  }

  void _initializeChewieController() {
    final videoController = ref.read(videoControllerProvider);

    if (videoController == null || !videoController.value.isInitialized) {
      return;
    }

    // Dispose del controller anterior si existe
    _chewieController?.dispose();

    // Detectar si estamos en TV (navegación direccional)
    final isTv =
        MediaQuery.of(context).navigationMode == NavigationMode.directional;

    // Crear nuevo Chewie controller
    // En TV: ocultar controles de Chewie y usar controles personalizados
    _chewieController = ChewieController(
      videoPlayerController: videoController,
      autoPlay: true,
      looping: false,
      autoInitialize: true,
      aspectRatio: 16 / 9,

      // En TV: ocultar controles de Chewie, usamos los nuestros
      // En móvil: mostrar controles normales
      showControls: !widget.isPipMode && !isTv,
      showControlsOnInitialize: !isTv,
      controlsSafeAreaMinimum: const EdgeInsets.all(8),

      // En móvil: ocultar después de unos segundos
      hideControlsTimer: const Duration(seconds: 3),

      // Configuración de UI
      materialProgressColors: ChewieProgressColors(
        playedColor: Theme.of(context).colorScheme.primary,
        handleColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.grey.withValues(alpha: 0.5),
        bufferedColor: Colors.grey.withValues(alpha: 0.3),
      ),

      placeholder: Container(
        color: Colors.black,
        child: const Center(child: CircularProgressIndicator()),
      ),

      allowFullScreen:
          false, // Deshabilitar fullscreen nativo, usaremos uno personalizado
      allowMuting: true,
      allowPlaybackSpeedChanging: false,
      showOptions: false,
    );

    setState(() {});
  }

  @override
  void dispose() {
    ChromecastService()
        .isConnectedNotifier
        .removeListener(_onCastingStateChanged);

    // Chewie pauses video on dispose. We must restore it if we want seamless transition to MiniPlayer.
    // Check if underlying controller is playing. Use CACHED controller to avoid ref error.
    final wasPlaying = _cachedVideoController?.value.isPlaying ?? false;

    _chewieController?.dispose();

    // Restore playback if it was playing and we are using the persistent controller
    if (wasPlaying && _cachedVideoController != null) {
      _cachedVideoController!.play();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Cache controller for safe access in dispose
    _cachedVideoController = ref.watch(videoControllerProvider);

    // Escuchar cambios en el estado para inicializar Chewie cuando esté listo
    // También reinicializar si el controller cambió (ej: después de cambio de URL)
    ref.listen(videoPlayerProvider, (previous, next) {
      final currentController = ref.read(videoControllerProvider);
      final needsInit = next.isInitialized && !next.hasError;
      final controllerChanged =
          currentController != _chewieController?.videoPlayerController;

      if (needsInit && (controllerChanged || _chewieController == null)) {
        AppLogger.info(
            '[FullVideoPlayer] Controller changed or new init, reinitializing Chewie');
        _initializeChewieController();
      }
    });

    final playerState = ref.watch(videoPlayerProvider);

    // WEB: Usar Custom Player directamente
    if (kIsWeb) {
      final streamUrl = ref.watch(configServiceProvider).streamUrl;
      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          // Usar widget de platform view con URL de ConfigService
          child: WebVideoPlayer(streamUrl: streamUrl, autoPlay: true),
        ),
      );
    }

    // Mostrar error si existe
    if (playerState.hasError) {
      return _buildErrorWidget(playerState.errorMessage);
    }

    // Mostrar loading si no está inicializado
    if (!playerState.isInitialized || _chewieController == null) {
      return _buildLoadingWidget();
    }

    // Mostrar el reproductor
    // Check local casting state (updated via listener)
    if (_isCasting) {
      return _buildCastingWidget();
    }

    // Detectar si estamos en TV
    final isTv = ref.watch(isTvProvider);

    // Si estamos en PiP o Desktop/TV, devolvemos solo el player sin restricciones de altura forzada
    if (widget.isPipMode ||
        MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint) {
      // En TV: Video + Barra de controles debajo
      if (isTv) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Video Player
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: Chewie(controller: _chewieController!),
              ),
            ),
            // Barra de controles debajo del video
            TVVideoControlsBar(
              videoController: _cachedVideoController,
              onToggleFullscreen: _toggleFullScreen,
            ),
          ],
        );
      }

      // No TV: Solo video con controles de Chewie
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Chewie(controller: _chewieController!),
        ),
      );
    }

    // Móvil portrait
    if (isTv) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 250),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: Colors.black,
                child: Chewie(controller: _chewieController!),
              ),
            ),
          ),
          // Barra de controles debajo del video
          TVVideoControlsBar(
            videoController: _cachedVideoController,
            onToggleFullscreen: _toggleFullScreen,
          ),
        ],
      );
    }

    // Móvil normal (no TV)
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 250),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: Chewie(controller: _chewieController!),
            ),
          ),
          // Botón de fullscreen en esquina inferior derecha
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: _enterFullScreen,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCastingWidget() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 250),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cast_connected, color: Colors.blue, size: 48),
              const SizedBox(height: 16),
              const Text(
                'Transmitiendo en TV',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'El video se está reproduciendo en tu Chromecast',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================================
  // WIDGETS AUXILIARES
  // ===================================

  Widget _buildLoadingWidget() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 250),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppConstants.spacingMd),
                Text(
                  'Cargando transmisión en vivo...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String? errorMessage) {
    final isTv = ref.watch(isTvProvider);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 250),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingLg),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: AppConstants.iconSizeXl,
                  ),
                  const SizedBox(height: AppConstants.spacingMd),
                  const Text(
                    'Error al cargar el video',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: AppConstants.spacingSm),
                    Text(
                      errorMessage,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: AppConstants.spacingLg),
                  if (isTv)
                    TVButton(
                      id: 'video_retry',
                      leftId: 'nav_0',
                      rightId: 'guide_day_0', // Conectar con contenido
                      downId: 'guide_program_0',
                      onPressed: () {
                        // Reintentar inicialización
                        ref.invalidate(videoPlayerProvider);
                      },
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh),
                          SizedBox(width: 8),
                          Text('Reintentar'),
                        ],
                      ),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () {
                        // Reintentar inicialización
                        ref.invalidate(videoPlayerProvider);
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget de pantalla completa para video player móvil
/// Se muestra como una ruta separada usando Navigator.push
class _FullScreenVideoPage extends StatefulWidget {
  final ChewieController chewieController;

  const _FullScreenVideoPage({
    required this.chewieController,
  });

  @override
  State<_FullScreenVideoPage> createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<_FullScreenVideoPage> {
  bool _showControls = true;

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  void _exitFullScreen() {
    // Restaurar orientaciones y UI del sistema
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Cerrar esta pantalla - esta página tiene su propio context válido
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _exitFullScreen();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: _toggleControls,
          child: Stack(
            children: [
              // Video a pantalla completa
              Positioned.fill(
                child: Center(
                  child: Chewie(controller: widget.chewieController),
                ),
              ),
              // Overlay de controles (siempre visible o toggle)
              if (_showControls)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Botón de salir de fullscreen
                            Material(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                onTap: _exitFullScreen,
                                child: const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Icon(
                                    Icons.fullscreen_exit,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
