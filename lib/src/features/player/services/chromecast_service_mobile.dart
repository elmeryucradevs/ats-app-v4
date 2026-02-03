import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

/// Mobile implementation of ChromecastService using flutter_chrome_cast
class ChromecastService {
  static final ChromecastService _instance = ChromecastService._internal();
  factory ChromecastService() => _instance;
  ChromecastService._internal();

  // Track discovered devices
  final List<GoogleCastDevice> _devices = [];
  bool _isDiscovering = false;
  StreamSubscription? _discoverySubscription;
  StreamSubscription? _sessionSubscription;
  // State for UI to react
  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);
  final bool _isInitialized = false;

  Future<void> initialize() async {
    developer.log('Initializing ChromecastService...',
        name: 'ChromecastService');
    try {
      if (_isInitialized) return;

      // Listen for session connection to update UI states
      _sessionSubscription = GoogleCastSessionManager
          .instance.currentSessionStream
          .listen((session) {
        if (session != null) {
          developer.log('STATE: Session Connected (Stream update)',
              name: 'ChromecastService');
          isConnectedNotifier.value = true;
          developer.log('UI: casting state set to TRUE',
              name: 'ChromecastService');

          // Centrally managed media loading with retry logic
          _attemptLoadMediaWithRetries();
        } else {
          developer.log('STATE: Session Disconnected (Stream update)',
              name: 'ChromecastService');
          isConnectedNotifier.value = false;
          developer.log('UI: casting state set to FALSE',
              name: 'ChromecastService');
        }
      });

      // Discovery
      _startDiscovery();
    } catch (e) {
      developer.log('Error initializing: $e', name: 'ChromecastService');
    }
  }

  // Helper to retry loading media
  bool _isLoadingMedia = false;
  Future<void> _attemptLoadMediaWithRetries(
      {int attempts = 3, BuildContext? context}) async {
    if (_isLoadingMedia) {
      developer.log('Skipping load retry: already in progress',
          name: 'ChromecastService');
      return;
    }
    _isLoadingMedia = true;

    for (int i = 0; i < attempts; i++) {
      developer.log('Attempting to load media (Attempt ${i + 1}/$attempts)...',
          name: 'ChromecastService');

      // First attempt fast, others with backoff
      final delay =
          i == 0 ? const Duration(milliseconds: 500) : Duration(seconds: 2);
      await Future.delayed(delay);

      try {
        if (GoogleCastSessionManager.instance.currentSession == null) {
          developer.log(
              'WARNING: Session appears null during retry, attempting anyway.',
              name: 'ChromecastService');
        }

        await loadMedia(
            'https://video2.getstreamhosting.com:19360/8016/8016.m3u8',
            title: 'ATESUR TV - En Vivo',
            context: context);

        developer.log('Media loaded successfully on attempt ${i + 1}',
            name: 'ChromecastService');
        _isLoadingMedia = false;
        return; // Success
      } catch (e) {
        developer.log('Media load failed on attempt ${i + 1}: $e',
            name: 'ChromecastService');
      }
    }

    developer.log('Failed to load media after $attempts attempts.',
        name: 'ChromecastService');
    _isLoadingMedia = false;
  }

  void dispose() {
    _discoverySubscription?.cancel();
    _sessionSubscription?.cancel();
  }

  void _startDiscovery() {
    if (_isDiscovering) return;
    try {
      _isDiscovering = true;
      _discoverySubscription =
          GoogleCastDiscoveryManager.instance.devicesStream.listen((devices) {
        _devices.clear();
        _devices.addAll(devices);
        developer.log('Discovered ${_devices.length} devices',
            name: 'ChromecastService');
      });
      GoogleCastDiscoveryManager.instance.startDiscovery();
    } catch (e) {
      developer.log('Error starting discovery: $e', name: 'ChromecastService');
      _isDiscovering = false;
    }
  }

  void openDeviceSelector(BuildContext parentContext) {
    developer.log('Opening device selector dialog', name: 'ChromecastService');
    if (!_isDiscovering) _startDiscovery();

    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Dispositivos Cercanos'),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<List<GoogleCastDevice>>(
            stream: GoogleCastDiscoveryManager.instance.devicesStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                developer.log('StreamBuilder Error: ${snapshot.error}',
                    name: 'ChromecastService');
                return Text('Error: ${snapshot.error}');
              }

              final devices = snapshot.data ?? _devices;
              developer.log(
                  'Device Selector Builder: ${devices.length} devices. Snapshot hasData: ${snapshot.hasData}',
                  name: 'ChromecastService');

              if (devices.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('Buscando dispositivos...'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  // developer.log('Rendering device item: ${device.friendlyName}', name: 'ChromecastService'); // Uncomment if needed, can be spammy
                  return ListTile(
                    leading: const Icon(Icons.cast),
                    title: Text(device.friendlyName),
                    subtitle: Text(device.modelName ?? 'Google Cast'),
                    onTap: () {
                      developer.log('Device tapped: ${device.friendlyName}',
                          name: 'ChromecastService');
                      Navigator.pop(dialogContext);
                      _connectToDevice(device, parentContext);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          if (isConnectedNotifier.value)
            TextButton(
              onPressed: () {
                _disconnect(parentContext);
                Navigator.pop(dialogContext);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Desconectar'),
            ),
          TextButton(
            onPressed: () {
              _startDiscovery();
              // Force rebuild if stream doesn't emit immediately (though it should)
              // (dialogContext as Element).markNeedsBuild(); // This is risky, better to just rely on stream
            },
            child: const Text('Actualizar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _connectToDevice(
      GoogleCastDevice device, BuildContext context) async {
    developer.log('=== START _connectToDevice for ${device.friendlyName} ===',
        name: 'ChromecastService');

    try {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conectando a ${device.friendlyName}...'),
            duration: const Duration(seconds: 3),
          ),
        );
      }

      if (GoogleCastSessionManager.instance.currentSession != null) {
        developer.log('Ending existing session...', name: 'ChromecastService');
        try {
          await GoogleCastSessionManager.instance
              .endSessionAndStopCasting()
              .timeout(const Duration(seconds: 2));
          developer.log('Session ended', name: 'ChromecastService');
        } catch (e) {
          developer.log(
              'Warning: Failed to end session cleanly or timed out: $e',
              name: 'ChromecastService');
        }
      }
      await Future.delayed(const Duration(milliseconds: 500));

      developer.log('Calling startSessionWithDevice...',
          name: 'ChromecastService');
      await GoogleCastSessionManager.instance
          .startSessionWithDevice(device)
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          developer.log('TIMEOUT calling startSessionWithDevice',
              name: 'ChromecastService');
          throw TimeoutException('Connection timeout after 15 seconds');
        },
      );
      developer.log('startSessionWithDevice returned successfully.',
          name: 'ChromecastService');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sincronizando sesión...'),
            duration: Duration(milliseconds: 500),
          ),
        );
      }

      // Manual verification: Wait a moment and check if session is active
      // often the stream might not fire if the plugin state is out of sync.
      // Polling for session to be active
      GoogleCastSession? session;
      for (int i = 0; i < 10; i++) {
        session = GoogleCastSessionManager.instance.currentSession;
        if (session != null) break;
        developer.log('Waiting for session to sync... ($i/10)',
            name: 'ChromecastService');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (session != null) {
        developer.log('Session confirmed manually via currentSession property.',
            name: 'ChromecastService');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Conectado! Iniciando video...'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Explicitly update UI state since stream might lag
        isConnectedNotifier.value = true;

        // Trigger media load with retries explicitly
        _attemptLoadMediaWithRetries(context: context);
      } else {
        developer.log(
            'WARNING: startSessionWithDevice returned but currentSession is null after polling.',
            name: 'ChromecastService');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Conectado! Iniciando video...'),
              backgroundColor: Colors.green,
            ),
          );
        }
        // Try anyway
        isConnectedNotifier.value = true;
        _attemptLoadMediaWithRetries(context: context);
      }
    } catch (e) {
      developer.log('ERROR in _connectToDevice: $e', name: 'ChromecastService');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('❌ Error Conexión: ${e.toString().split('\n').first}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget buildCastButton({required BuildContext context}) {
    return IconButton(
      icon: const Icon(Icons.cast),
      onPressed: () => openDeviceSelector(context),
      tooltip: 'Transmitir a Chromecast',
    );
  }

  Future<void> loadMedia(String mediaUrl,
      {String title = 'ATESUR TV', BuildContext? context}) async {
    try {
      final session = GoogleCastSessionManager.instance.currentSession;
      if (session == null) {
        developer.log(
            'WARNING: currentSession is null in loadMedia. Attempting load anyway.',
            name: 'ChromecastService');
      }

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enviando video: $title...'),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      developer.log('Loading media: $mediaUrl', name: 'ChromecastService');

      /*
      // DEBUG: Use this sample video to test if the connection works but the stream fails
      await GoogleCastRemoteMediaClient.instance.loadMedia(
        GoogleCastMediaInformation(
          contentId: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
            streamType: CastMediaStreamType.buffered,
            contentUrl: Uri.parse('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4'),
            contentType: 'video/mp4',
            metadata: GoogleCastMediaMetadata(
              metadataType: GoogleCastMediaMetadataType.values.first,
               images: [
                 GoogleCastImage(
                   url: Uri.parse('https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/images/BigBuckBunny.jpg'),
                   width: 480,
                   height: 360,
                 )
               ],
            ),
        ),
        autoPlay: true,
         playPosition: Duration.zero,
      );
      */

      developer.log('DEBUG: Loading Production HLS Stream',
          name: 'ChromecastService');

      await GoogleCastRemoteMediaClient.instance.loadMedia(
        GoogleCastMediaInformation(
          contentId: mediaUrl,
          streamType: CastMediaStreamType.live,
          contentUrl: Uri.parse(mediaUrl),
          contentType: 'application/x-mpegURL',
          metadata: GoogleCastMediaMetadata(
            metadataType: GoogleCastMediaMetadataType.values.first,
            images: [
              GoogleCastImage(
                url: Uri.parse(
                    'https://res.cloudinary.com/dzddovfkf/image/upload/v1767708339/logo_wjpofg.png'),
                width: 500,
                height: 500,
              ),
            ],
          ),
        ),
        autoPlay: true,
        playPosition: Duration.zero,
      );

      developer.log('Media load command sent', name: 'ChromecastService');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Video enviado al TV'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      developer.log('Error in loadMedia: $e', name: 'ChromecastService');
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al enviar video: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _disconnect(BuildContext context) async {
    developer.log('Disconnecting session...', name: 'ChromecastService');
    // Optimistically update UI
    isConnectedNotifier.value = false;

    try {
      await GoogleCastSessionManager.instance.endSessionAndStopCasting();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Desconectado'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      developer.log('Error disconnecting: $e', name: 'ChromecastService');
      // Ensure it stays false
      isConnectedNotifier.value = false;
    }
  }
}
