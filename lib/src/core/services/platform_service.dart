import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';

/// Servicio para detectar características de la plataforma
class PlatformService {
  PlatformService._();
  static final PlatformService instance = PlatformService._();

  bool _isTv = false;
  bool _initialized = false;

  /// Retorna true si el dispositivo es detectado como TV
  bool get isTv => _isTv;

  /// Inicializa la detección de plataforma
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      if (kIsWeb) {
        _isTv = false;
      } else if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        // Check for official Android TV feature
        _isTv =
            androidInfo.systemFeatures.contains('android.software.leanback');
        AppLogger.info('[PlatformService] Android TV detected: $_isTv');
      } else {
        // iOS/Desktop/etc logic if needed (usually not TV)
        _isTv = false;
      }
    } catch (e) {
      AppLogger.error('[PlatformService] Error detecting platform', e);
      _isTv = false;
    } finally {
      _initialized = true;
    }
  }
}

/// Notifier para gestionar el estado de detección de TV
class TvDetectionNotifier extends Notifier<bool> {
  @override
  bool build() {
    return PlatformService.instance.isTv;
  }

  void update(bool isTv) {
    state = isTv;
  }
}

/// Provider que expone si es un TV.
final isTvProvider = NotifierProvider<TvDetectionNotifier, bool>(() {
  return TvDetectionNotifier();
});

/// Inicializador asíncrono que actualiza el provider
final platformInitializerProvider = FutureProvider<void>((ref) async {
  await PlatformService.instance.initialize();
  ref.read(isTvProvider.notifier).update(PlatformService.instance.isTv);
});
