import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/app_logger.dart';

/// Configuración de variables de entorno
///
/// Sistema híbrido que soporta:
/// - Mobile/Desktop: Lee de .env usando flutter_dotenv
/// - Web: Usa const String.fromEnvironment() con --dart-define
///
/// Para compilar para web con variables de entorno:
/// ```bash
/// flutter build web --dart-define=STREAM_URL=https://... --dart-define=SUPABASE_URL=https://...
/// ```
class EnvConfig {
  // Constructor privado para evitar instanciación
  EnvConfig._();

  /// Helper para obtener valor según plataforma
  static String _getPlatformValue(
    String key, {
    required String fallback,
    String? webFallback,
  }) {
    if (kIsWeb) {
      // En web, usar --dart-define o fallback específico de web
      // Nota: String.fromEnvironment solo funciona con constantes
      // Por lo tanto, debemos retornar el fallback para web
      return webFallback ?? fallback;
    } else {
      // En móvil/desktop, usar dotenv
      try {
        return dotenv.get(key, fallback: fallback);
      } catch (e) {
        AppLogger.warning(
          '[EnvConfig] Error leyendo $key desde .env, usando fallback',
        );
        return fallback;
      }
    }
  }

  // ===================================
  // STREAMING
  // ===================================

  /// URL del stream de video HLS (.m3u8)
  static String get streamUrl => _getPlatformValue(
    'STREAM_URL',
    fallback: 'https://video2.getstreamhosting.com:19360/8016/8016.m3u8',
  );

  // ===================================
  // SUPABASE
  // ===================================

  /// URL del proyecto Supabase
  static String get supabaseUrl => _getPlatformValue(
    'SUPABASE_URL',
    fallback: '',
    webFallback: 'https://kholyiqxboourdwavkci.supabase.co',
  );

  /// Clave anónima de Supabase (es segura para el cliente)
  static String get supabaseAnonKey => _getPlatformValue(
    'SUPABASE_ANON_KEY',
    fallback: '',
    webFallback:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imtob2x5aXF4Ym9vdXJkd2F2a2NpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjYyMzQ3MzcsImV4cCI6MjA4MTgxMDczN30.4Si0xrOmlnMRtG22IVy83qdZ5eDdR5DmSM2Z1hhCIFE',
  );

  // ===================================
  // WORDPRESS API (Opcional)
  // ===================================

  /// URL base de la API REST de WordPress
  static String get wordpressApiUrl => _getPlatformValue(
    'WORDPRESS_API_URL',
    fallback: '',
    webFallback:
        'https://atesurplus.wordpress.com/wp-json/wp/v2', // Ajustar según tu WordPress
  );

  // ===================================
  // FIREBASE (FCM)
  // ===================================

  /// ID del proyecto Firebase (solo referencia)
  static String get firebaseProjectId => _getPlatformValue(
    'FIREBASE_PROJECT_ID',
    fallback: '',
    webFallback: 'atesur-app-v4',
  );

  /// Key par de llaves VAPID para Web Push (generado en Firebase Console -> Cloud Messaging -> Web Configuration)
  static String get firebaseVapidKey => _getPlatformValue(
    'FIREBASE_VAPID_KEY',
    fallback: '',
    webFallback:
        'BEeiXTObBbEgoc5JI7_mZygI3rUFIDfdCjBEDCQX2KSEyaQeSRvOvapmOGPjKtYYwxA7OJckDkpmMXtg4tvWOHI',
  );

  // ===================================
  // INFORMACIÓN DEL CANAL
  // ===================================

  /// Nombre del canal de TV
  static String get channelName =>
      _getPlatformValue('CHANNEL_NAME', fallback: 'ATESUR');

  /// URL del logo del canal
  static String get channelLogoUrl =>
      _getPlatformValue('CHANNEL_LOGO_URL', fallback: '');

  // ===================================
  // REDES SOCIALES
  // ===================================

  static String get facebookUrl => _getPlatformValue(
    'FACEBOOK_URL',
    fallback: 'https://www.facebook.com/atesurplus',
  );

  static String get twitterUrl => _getPlatformValue(
    'TWITTER_URL',
    fallback: 'https://twitter.com/atesurplus',
  );

  static String get instagramUrl => _getPlatformValue(
    'INSTAGRAM_URL',
    fallback: 'https://www.instagram.com/atesurplus',
  );

  static String get youtubeUrl => _getPlatformValue(
    'YOUTUBE_URL',
    fallback: 'https://www.youtube.com/@atesurplus',
  );

  static String get tiktokUrl => _getPlatformValue(
    'TIKTOK_URL',
    fallback: 'https://www.tiktok.com/@atesurplus',
  );

  static String get whatsappUrl => _getPlatformValue(
    'WHATSAPP_URL',
    fallback: 'https://wa.me/5949999999999',
  );

  /// Email de contacto
  static String get contactEmail =>
      _getPlatformValue('CONTACT_EMAIL', fallback: 'contacto@atesur.com');

  // ===================================
  // DESARROLLO
  // ===================================

  /// Habilitar logs de debug
  static bool get debugMode {
    if (kIsWeb) {
      const value = String.fromEnvironment('DEBUG_MODE');
      return value == 'true';
    } else {
      try {
        return dotenv.get('DEBUG_MODE', fallback: 'false') == 'true';
      } catch (e) {
        return false;
      }
    }
  }

  /// Modo de prueba (deshabilita ciertas validaciones)
  static bool get testMode {
    if (kIsWeb) {
      const value = String.fromEnvironment('TEST_MODE');
      return value == 'true';
    } else {
      try {
        return dotenv.get('TEST_MODE', fallback: 'false') == 'true';
      } catch (e) {
        return false;
      }
    }
  }

  // ===================================
  // VALIDACIÓN
  // ===================================

  /// Valida que las configuraciones críticas estén presentes
  static void validate() {
    final errors = <String>[];

    if (streamUrl.isEmpty) {
      errors.add('STREAM_URL no está configurada');
    }

    if (supabaseUrl.isEmpty) {
      errors.add('SUPABASE_URL no está configurada');
    }

    if (supabaseAnonKey.isEmpty) {
      errors.add('SUPABASE_ANON_KEY no está configurada');
    }

    if (errors.isNotEmpty) {
      AppLogger.warning(
        '[EnvConfig] ⚠️ Configuración incompleta:\n${errors.join('\n')}',
      );
      if (!kIsWeb && !testMode) {
        throw Exception(
          'Configuración de entorno incompleta. '
          'Revisa tu archivo .env',
        );
      }
    } else {
      AppLogger.info(
        '[EnvConfig] ✅ Todas las configuraciones cargadas correctamente',
      );
    }
  }

  /// Imprime las configuraciones (sin exponer claves sensibles)
  static void printConfig() {
    AppLogger.info('''
[EnvConfig] Configuración actual:
  Plataforma: ${kIsWeb ? 'Web' : 'Mobile/Desktop'}
  Stream URL: ${streamUrl.isNotEmpty ? '✓' : '✗'}
  Supabase URL: ${supabaseUrl.isNotEmpty ? '✓' : '✗'}
  Supabase Key: ${supabaseAnonKey.isNotEmpty ? '✓' : '✗'}
  WordPress API: ${wordpressApiUrl.isNotEmpty ? '✓' : '✗'}
  Debug Mode: $debugMode
  Test Mode: $testMode
    ''');
  }
}
