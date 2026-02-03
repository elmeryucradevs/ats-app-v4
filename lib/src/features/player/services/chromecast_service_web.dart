import 'dart:developer' as developer;
import 'dart:js_interop';
import 'package:flutter/material.dart';

// External JS function to evaluate code
@JS('eval')
external JSAny? _jsEval(JSAny code);

/// Service to handle Chromecast functionality for web
/// Uses @JS annotations for dart:js_interop compatibility
class ChromecastService {
  static final ChromecastService _instance = ChromecastService._internal();
  factory ChromecastService() => _instance;
  ChromecastService._internal();

  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);

  bool _initialized = false;

  /// Check if Cast API is available
  bool get isAvailable {
    try {
      final result = _evalJS('typeof cast !== "undefined"');
      return result?.dartify() == true;
    } catch (e) {
      developer.log('Cast API not available: $e', name: 'ChromecastService');
      return false;
    }
  }

  /// Initialize Cast context
  Future<void> initialize() async {
    if (_initialized) return;
    if (!isAvailable) {
      developer.log('Cast SDK not loaded', name: 'ChromecastService');
      return;
    }

    try {
      // Wait for Cast API to be ready
      _evalJS('''
        window.__onGCastApiAvailable = function(isAvailable) {
          if (isAvailable) {
            console.log('[ChromecastService] Cast API ready');
            window.__dartCastSetupContext();
          }
        };
      ''');

      // Define setup function
      _setupCastContext();
      _initialized = true;
    } catch (e) {
      developer.log('Error initializing: $e', name: 'ChromecastService');
    }
  }

  void _setupCastContext() {
    try {
      // Configuramos el contexto y definimos la función global de ayuda
      _evalJS('''
        window.__dartCastSetupContext = function() {
          try {
            // 1. Configurar Cast Context
            var castContext = cast.framework.CastContext.getInstance();
            castContext.setOptions({
              receiverApplicationId: chrome.cast.media.DEFAULT_MEDIA_RECEIVER_APP_ID,
              autoJoinPolicy: chrome.cast.AutoJoinPolicy.ORIGIN_SCOPED
            });
            console.log('[ChromecastService] Cast context configured');

            // 2. Definir función global para reproducir
            window.playOnChromecast = function(mediaUrl, title) {
                console.log('[ChromecastService] Requesting playback for:', title);
                var context = cast.framework.CastContext.getInstance();
                var session = context.getCurrentSession();

                function loadMedia(currentSession) {
                    var mediaInfo = new chrome.cast.media.MediaInfo(mediaUrl, 'application/x-mpegURL');
                    mediaInfo.streamType = chrome.cast.media.StreamType.LIVE;
                    mediaInfo.metadata = new chrome.cast.media.GenericMediaMetadata();
                    mediaInfo.metadata.title = title;
                    mediaInfo.metadata.subtitle = 'Streaming en vivo';
                    
                    var request = new chrome.cast.media.LoadRequest(mediaInfo);
                    request.autoplay = true;

                    currentSession.loadMedia(request).then(
                        function() { console.log('[ChromecastService] Media load success'); },
                        function(e) { console.error('[ChromecastService] Media load error:', e); }
                    );
                }

                if (!session) {
                    console.log('[ChromecastService] No session, requesting...');
                    context.requestSession().then(
                        function() {
                            // Éxito al conectar
                            var newSession = context.getCurrentSession();
                            if (newSession) {
                                loadMedia(newSession);
                            }
                        },
                        function(e) {
                            console.error('[ChromecastService] Message from requestSession:', e);
                        }
                    );
                } else {
                    loadMedia(session);
                }
            };
          } catch (e) {
            console.error('[ChromecastService] Setup error:', e);
          }
        };
        
        // Call setup immediately if cast is already available
        if (typeof cast !== 'undefined') {
          window.__dartCastSetupContext();
        }
      ''');
    } catch (e) {
      developer.log('Error setting up context: $e', name: 'ChromecastService');
    }
  }

  /// Open the Cast device selector
  void openDeviceSelector(BuildContext parentContext) {
    if (!isAvailable) return;
    try {
      _evalJS('cast.framework.CastContext.getInstance().requestSession()');
    } catch (e) {
      developer.log('Error opening selector: $e', name: 'ChromecastService');
    }
  }

  Widget buildCastButton({required BuildContext context}) {
    return IconButton(
      icon: const Icon(Icons.cast),
      onPressed: () => openDeviceSelector(context),
      tooltip: 'Transmitir a Chromecast',
    );
  }

  /// Open the Cast device selector

  /// Load media to Chromecast
  Future<void> loadMedia(String mediaUrl, {String title = 'ATESUR TV'}) async {
    if (!isAvailable) {
      developer.log('Cast not available', name: 'ChromecastService');
      return;
    }

    try {
      // Check if function exists
      final hasFn = _evalJS('typeof window.playOnChromecast === "function"');
      if (hasFn?.dartify() == true) {
        _evalJS(
          'window.playOnChromecast("${_escapeJS(mediaUrl)}", "${_escapeJS(title)}")',
        );
      } else {
        developer.log(
          'playOnChromecast function not found',
          name: 'ChromecastService',
        );
        // Reintentar setup si se perdió
        _setupCastContext();
        // Darle un momento y reintentar
        Future.delayed(const Duration(milliseconds: 100), () {
          _evalJS(
            'window.playOnChromecast("${_escapeJS(mediaUrl)}", "${_escapeJS(title)}")',
          );
        });
      }
    } catch (e) {
      developer.log('Error calling loadMedia: $e', name: 'ChromecastService');
    }
  }

  // Helper to escape JavaScript strings
  String _escapeJS(String str) {
    return str
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  // Helper to evaluate JavaScript
  JSAny? _evalJS(String code) {
    try {
      return _jsEval(code.toJS);
    } catch (e) {
      developer.log('Error evaluating JS: $e', name: 'ChromecastService');
      return null;
    }
  }
}
