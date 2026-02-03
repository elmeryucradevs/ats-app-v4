import 'package:video_player/video_player.dart';

import '../../../core/utils/app_logger.dart';

// Soporte HLS para web
import 'package:flutter/foundation.dart' show kIsWeb;

// Importación condicional: solo se importa en web
// En mobile/desktop se importa un stub vacío

/// Servicio para gestionar el reproductor de video
///
/// Proporciona una capa de abstracción sobre VideoPlayerController
/// para manejar el streaming HLS y el ciclo de vida del reproductor.
class VideoPlayerService {
  VideoPlayerService._();

  /// Instancia única del servicio
  static final VideoPlayerService instance = VideoPlayerService._();

  /// Controller actual del video player
  VideoPlayerController? _controller;

  /// Getter del controller
  VideoPlayerController? get controller => _controller;

  /// Indica si el reproductor está inicializado
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  /// Indica si el video está reproduciendo
  bool get isPlaying => _controller?.value.isPlaying ?? false;

  /// Posición actual del video
  Duration get position => _controller?.value.position ?? Duration.zero;

  /// Duración total del video
  Duration get duration => _controller?.value.duration ?? Duration.zero;

  /// Volumen actual (0.0 - 1.0)
  double get volume => _controller?.value.volume ?? 1.0;

  // ===================================
  // INICIALIZACIÓN
  // ===================================

  /// Inicializa el reproductor con una URL de stream
  ///
  /// [streamUrl]: URL del stream HLS (.m3u8)
  /// [autoPlay]: Si debe iniciar automáticamente
  Future<bool> initialize({
    required String streamUrl,
    bool autoPlay = true,
  }) async {
    try {
      AppLogger.info('[VideoPlayer] Inicializando con URL: $streamUrl');

      // Web: El player se maneja independientemente con HtmlElementView
      if (kIsWeb) {
        AppLogger.info(
          '[VideoPlayer] 🌐 Web: Usando HtmlElementView custom player',
        );
        return true;
      }

      // Disponer del controller anterior si existe
      await dispose();

      AppLogger.debug(
          '[VideoPlayer] Creando VideoPlayerController con URL: $streamUrl');
      // Crear nuevo controller con la URL del stream
      _controller = PersistentVideoPlayerController.networkUrl(
        Uri.parse(streamUrl),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: true, // Permite audio de otras apps
          allowBackgroundPlayback: false, // Por ahora no en background
        ),
      );

      AppLogger.debug(
          '[VideoPlayer] Controller creado, llamando a initialize()...');
      // Inicializar el controller con timeout para evitar loading infinito
      try {
        await _controller!.initialize().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            AppLogger.error(
                '[VideoPlayer] ❌ Timeout al inicializar video (15s)');
            throw Exception(
                'Timeout: El stream tardó más de 15 segundos en responder');
          },
        );
        AppLogger.debug('[VideoPlayer] initialize() completado exitosamente.');
      } catch (initError) {
        AppLogger.error(
            '[VideoPlayer] ❌ Error o Timeout en initialize(): $initError');
        _controller = null;
        rethrow;
      }

      // Guard: Controller might be null if dispose was called during init
      if (_controller == null) {
        AppLogger.warning(
            '[VideoPlayer] Controller was disposed during init (post-await check)');
        return false;
      }

      AppLogger.debug(
        '[VideoPlayer] Controller inicializado, añadiendo listener...',
      );
      // Configurar listeners
      _controller!.addListener(_onPlayerStateChanged);

      AppLogger.info('[VideoPlayer] ✅ Inicializado correctamente');

      // Auto-play si está habilitado
      if (autoPlay) {
        AppLogger.debug('[VideoPlayer] Iniciando auto-play...');
        await play();
      }

      return true;
    } catch (e, stackTrace) {
      AppLogger.error('[VideoPlayer] ❌ Error al inicializar', e, stackTrace);
      // Clean up controller if it exists but failed
      _controller = null;
      return false;
    }
  }

  // ===================================
  // CONTROLES DE REPRODUCCIÓN
  // ===================================

  /// Reproduce el video
  Future<void> play() async {
    try {
      if (_controller == null) {
        AppLogger.warning('[VideoPlayer] No hay controller inicializado');
        return;
      }

      await _controller!.play();
      AppLogger.debug('[VideoPlayer] ▶️ Reproduciendo');
    } catch (e) {
      AppLogger.error('[VideoPlayer] Error al reproducir', e);
    }
  }

  /// Pausa el video
  Future<void> pause() async {
    try {
      if (_controller == null) return;

      await _controller!.pause();
      AppLogger.debug('[VideoPlayer] ⏸️ Pausado');
    } catch (e) {
      AppLogger.error('[VideoPlayer] Error al pausar', e);
    }
  }

  /// Alterna entre play/pause
  Future<void> togglePlayPause() async {
    if (isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  /// Busca a una posición específica del video
  ///
  /// NOTA: Para streams en vivo (HLS), esto puede no funcionar
  Future<void> seekTo(Duration position) async {
    try {
      if (_controller == null) return;

      await _controller!.seekTo(position);
      AppLogger.debug('[VideoPlayer] Buscando a: ${position.inSeconds}s');
    } catch (e) {
      AppLogger.error('[VideoPlayer] Error al buscar posición', e);
    }
  }

  // ===================================
  // CONFIGURACIÓN
  // ===================================

  /// Establece el volumen del reproductor
  ///
  /// [volume]: Valor entre 0.0 (mute) y 1.0 (máximo)
  Future<void> setVolume(double volume) async {
    try {
      if (_controller == null) return;

      final clampedVolume = volume.clamp(0.0, 1.0);
      await _controller!.setVolume(clampedVolume);
      AppLogger.debug(
        '[VideoPlayer] Volumen: ${(clampedVolume * 100).toInt()}%',
      );
    } catch (e) {
      AppLogger.error('[VideoPlayer] Error al ajustar volumen', e);
    }
  }

  /// Activa/desactiva el modo mute
  Future<void> toggleMute() async {
    if (volume > 0) {
      await setVolume(0.0);
    } else {
      await setVolume(1.0);
    }
  }

  /// Establece la velocidad de reproducción
  ///
  /// [speed]: Velocidad (0.5 = lento, 1.0 = normal, 2.0 = rápido)
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      if (_controller == null) return;

      await _controller!.setPlaybackSpeed(speed);
      AppLogger.debug('[VideoPlayer] Velocidad: ${speed}x');
    } catch (e) {
      AppLogger.error('[VideoPlayer] Error al ajustar velocidad', e);
    }
  }

  // ===================================
  // LISTENERS
  // ===================================

  /// Callback cuando cambia el estado del reproductor
  void _onPlayerStateChanged() {
    if (_controller == null) return;

    final value = _controller!.value;

    // Log de cambios importantes
    if (value.hasError) {
      AppLogger.error(
        '[VideoPlayer] Error en reproducción: ${value.errorDescription}',
      );
    }

    if (value.isBuffering) {
      AppLogger.debug('[VideoPlayer] Buffering...');
    }
  }

  // ===================================
  // LIMPIEZA
  // ===================================

  /// Libera los recursos del reproductor
  Future<void> dispose() async {
    try {
      if (_controller != null) {
        AppLogger.debug('[VideoPlayer] Liberando recursos...');

        await _controller!.pause();
        _controller!.removeListener(_onPlayerStateChanged);

        // Handle custom persistent controller
        if (_controller is PersistentVideoPlayerController) {
          await (_controller as PersistentVideoPlayerController).forceDispose();
        } else {
          await _controller!.dispose();
        }

        _controller = null;

        AppLogger.info('[VideoPlayer] ✅ Recursos liberados');
      }
    } catch (e) {
      AppLogger.error('[VideoPlayer] Error al liberar recursos', e);
    }
  }
}

/// Wrapper para evitar que Chewie disponga el controller
class PersistentVideoPlayerController extends VideoPlayerController {
  PersistentVideoPlayerController.networkUrl(
    super.url, {
    super.formatHint,
    super.closedCaptionFile,
    super.videoPlayerOptions,
    super.httpHeaders,
  }) : super.networkUrl();

  @override
  // ignore: must_call_super
  Future<void> dispose() async {
    // IGNORAR DISPOSE EXTERNO (e.g. de Chewie)
    AppLogger.debug('[Persistent] Ignorando dispose de consumer');
  }

  /// Dispose real llamado solo por el servicio
  Future<void> forceDispose() async {
    AppLogger.debug('[Persistent] Forzando dispose real');
    await super.dispose();
  }
}
