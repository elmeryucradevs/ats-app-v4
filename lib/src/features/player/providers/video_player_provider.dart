import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../services/video_player_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/config_service.dart';

// Importar el sistema unificado de programación
import '../../schedule/services/schedule_service.dart' as unified;
import '../../schedule/models/program_model.dart';
import '../../schedule/providers/schedule_provider.dart' as schedule_providers;

// ===================================
// ESTADO DEL REPRODUCTOR
// ===================================

/// Estado del reproductor de video
class VideoPlayerState {
  final bool isInitialized;
  final bool isPlaying;
  final bool isBuffering;
  final bool isMuted;
  final double volume;
  final Duration position;
  final Duration duration;
  final bool hasError;
  final String? errorMessage;
  final bool isMinimized; // Para el mini player

  const VideoPlayerState({
    this.isInitialized = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isMuted = false,
    this.volume = 1.0,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.hasError = false,
    this.errorMessage,
    this.isMinimized = false,
  });

  VideoPlayerState copyWith({
    bool? isInitialized,
    bool? isPlaying,
    bool? isBuffering,
    bool? isMuted,
    double? volume,
    Duration? position,
    Duration? duration,
    bool? hasError,
    String? errorMessage,
    bool? isMinimized,
  }) {
    return VideoPlayerState(
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isMuted: isMuted ?? this.isMuted,
      volume: volume ?? this.volume,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      isMinimized: isMinimized ?? this.isMinimized,
    );
  }
}

// ===================================
// NOTIFIER DEL REPRODUCTOR
// ===================================

/// Notifier para gestionar el estado del reproductor
class VideoPlayerNotifier extends Notifier<VideoPlayerState> {
  final _service = VideoPlayerService.instance;
  VideoPlayerController? _controller;
  bool _isInitializing = false; // Guard against concurrent initializations
  String? _lastInitializedUrl; // Track last URL to avoid redundant re-init
  String? _pendingUrl; // URL that arrived during initialization

  @override
  VideoPlayerState build() {
    // Listen to URL changes to re-init (but only if URL actually changes)
    ref.listen(configServiceProvider.select((s) => s.streamUrl),
        (previous, next) {
      AppLogger.info(
        '[VideoPlayerProvider] URL listener fired: previous=$previous, next=$next, '
        'lastInit=$_lastInitializedUrl, isInitializing=$_isInitializing',
      );

      // If URL is different from what we initialized with
      if (next != _lastInitializedUrl) {
        if (_isInitializing) {
          // Save pending URL to init after current completes
          AppLogger.info(
              '[VideoPlayerProvider] URL changed during init, queuing for later: $next');
          _pendingUrl = next;
        } else {
          AppLogger.info(
              '[VideoPlayerProvider] Stream URL changed, reinitializing with: $next');
          _initialize();
        }
      }
    });

    // Inicializar reproductor (side-effect seguro, only once)
    Future.microtask(() => _initialize());

    // Limpieza al eliminar el provider
    ref.onDispose(() {
      _controller?.removeListener(_updateState);
      _service.dispose();
    });

    return const VideoPlayerState();
  }

  /// Inicializa el reproductor con el stream del canal
  Future<void> _initialize() async {
    // Guard: prevent concurrent initializations
    if (_isInitializing) {
      AppLogger.warning(
          '[VideoPlayerProvider] Skipping - already initializing');
      return;
    }
    _isInitializing = true;
    _pendingUrl = null; // Clear pending URL since we're starting init

    try {
      AppLogger.info('[VideoPlayerProvider] Inicializando reproductor...');

      // Get URL from ConfigService state
      final config = ref.read(configServiceProvider);
      final streamUrl = config.streamUrl;

      // Skip if same URL already initialized
      if (streamUrl == _lastInitializedUrl &&
          state.isInitialized &&
          !state.hasError) {
        AppLogger.info('[VideoPlayerProvider] URL unchanged, skipping re-init');
        _isInitializing = false;
        return;
      }

      _lastInitializedUrl = streamUrl;

      final success = await _service.initialize(
        streamUrl: streamUrl,
        autoPlay: true,
      );

      if (success) {
        _controller = _service.controller;

        // En web, no hay controller pero el player funciona
        if (_controller != null) {
          _setupListener();
          _updateState();
        } else {
          // Web: marcar como inicializado manualmente
          state = state.copyWith(isInitialized: true, isPlaying: true);
          AppLogger.info('[VideoPlayerProvider] ✅ Web player inicializado');
        }
      } else {
        state = state.copyWith(
          hasError: true,
          errorMessage: 'No se pudo inicializar el reproductor',
        );
      }
    } catch (e) {
      AppLogger.error('[VideoPlayerProvider] Error en inicialización', e);
      state = state.copyWith(hasError: true, errorMessage: e.toString());
    } finally {
      _isInitializing = false;

      // Check if a new URL arrived during initialization
      if (_pendingUrl != null && _pendingUrl != _lastInitializedUrl) {
        AppLogger.info(
            '[VideoPlayerProvider] Reinitializing with pending URL: $_pendingUrl');
        _pendingUrl = null;
        _initialize(); // Reinit with the new URL
      }
    }
  }

  /// Configura el listener del controller
  void _setupListener() {
    _controller?.addListener(_updateState);
  }

  /// Actualiza el estado basado en el controller
  void _updateState() {
    if (_controller == null) return;

    final value = _controller!.value;

    state = state.copyWith(
      isInitialized: value.isInitialized,
      isPlaying: value.isPlaying,
      isBuffering: value.isBuffering,
      volume: value.volume,
      position: value.position,
      duration: value.duration,
      hasError: value.hasError,
      errorMessage: value.errorDescription,
      isMuted: value.volume == 0,
    );
  }

  // ===================================
  // CONTROLES
  // ===================================

  Future<void> play() async {
    await _service.play();
  }

  Future<void> pause() async {
    await _service.pause();
  }

  Future<void> togglePlayPause() async {
    await _service.togglePlayPause();
  }

  Future<void> setVolume(double volume) async {
    await _service.setVolume(volume);
  }

  Future<void> toggleMute() async {
    await _service.toggleMute();
  }

  Future<void> seekTo(Duration position) async {
    await _service.seekTo(position);
  }

  // ===================================
  // MINI PLAYER
  // ===================================

  void minimizePlayer() {
    state = state.copyWith(isMinimized: true);
    AppLogger.debug('[VideoPlayerProvider] Player minimizado');
  }

  void maximizePlayer() {
    state = state.copyWith(isMinimized: false);
    AppLogger.debug('[VideoPlayerProvider] Player maximizado');
  }

  void toggleMinimize() {
    if (state.isMinimized) {
      maximizePlayer();
    } else {
      minimizePlayer();
    }
  }
}

// ===================================
// PROVIDERS
// ===================================

/// Provider del estado del reproductor
final videoPlayerProvider =
    NotifierProvider<VideoPlayerNotifier, VideoPlayerState>(() {
  return VideoPlayerNotifier();
});

/// Provider del controller (para Chewie y uso directo)
final videoControllerProvider = Provider<VideoPlayerController?>((ref) {
  // Watch state to trigger rebuilds when initialized/updated
  final state = ref.watch(videoPlayerProvider);
  if (!state.isInitialized) return null;

  return VideoPlayerService.instance.controller;
});

// ===================================
// PROVIDERS DE PROGRAMACIÓN (UNIFICADOS CON REALTIME)
// ===================================

/// Provider del servicio de programación unificado
final scheduleServiceProvider = Provider<unified.ScheduleService>((ref) {
  return unified.ScheduleService.instance;
});

/// Provider de todos los programas (con Realtime)
final allProgramsProvider = FutureProvider<List<Program>>((ref) async {
  // Watch refresh trigger para invalidar cuando hay cambios en Realtime
  ref.watch(schedule_providers.scheduleRefreshProvider);

  final service = ref.watch(scheduleServiceProvider);
  return service.getAllPrograms();
});

/// Provider del programa actual EN VIVO (con Realtime)
final currentProgramProvider = FutureProvider<Program?>((ref) async {
  // Watch refresh trigger para invalidar cuando hay cambios en Realtime
  ref.watch(schedule_providers.scheduleRefreshProvider);

  final service = ref.watch(scheduleServiceProvider);
  return service.getCurrentProgram();
});

/// Provider del próximo programa (con Realtime)
final nextProgramProvider = FutureProvider<Program?>((ref) async {
  // Watch refresh trigger para invalidar cuando hay cambios en Realtime
  ref.watch(schedule_providers.scheduleRefreshProvider);

  final service = ref.watch(scheduleServiceProvider);
  return service.getNextProgram();
});

/// Provider de programas por día (con Realtime)
final programsByDayProvider = FutureProvider.family<List<Program>, int>((
  ref,
  dayOfWeek,
) async {
  // Watch refresh trigger para invalidar cuando hay cambios en Realtime
  ref.watch(schedule_providers.scheduleRefreshProvider);

  final service = ref.watch(scheduleServiceProvider);
  return service.getProgramsByDay(dayOfWeek);
});

/// Provider para refrescar la programación
final refreshScheduleProvider = Provider<void Function()>((ref) {
  return () {
    // Incrementar el contador de refresh para invalidar todos los providers
    ref.read(schedule_providers.scheduleRefreshProvider.notifier).refresh();
    AppLogger.info('[Providers] Programación refrescada');
  };
});
