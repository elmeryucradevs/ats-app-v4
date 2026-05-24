import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import '../config/env_config.dart';
import '../utils/app_logger.dart';

/// Servicio de Supabase
///
/// Proporciona acceso centralizado al cliente de Supabase para toda la aplicación.
/// Gestiona la inicialización y proporciona helpers para operaciones comunes.
class SupabaseService {
  // Constructor privado (singleton)
  SupabaseService._();

  /// Instancia única del servicio
  static final SupabaseService instance = SupabaseService._();

  /// Indica si Supabase ya fue inicializado
  static bool _initialized = false;

  /// Cliente de Supabase (acceso directo)
  static SupabaseClient get client => Supabase.instance.client;

  /// Canal activo resuelto para multi-tenancy dinámico
  static String channelId = 'd0000000-0000-0000-0000-000000000000';

  /// Resuelve dinámicamente el ID del canal en base al package name o URL web
  static Future<void> resolveChannelId() async {
    try {
      if (EnvConfig.channelId.isNotEmpty) {
        channelId = EnvConfig.channelId;
        AppLogger.info('[SupabaseService] ✅ Usando channel_id forzado de .env: $channelId');
        return;
      }

      String? packageId;
      if (!kIsWeb) {
        final packageInfo = await PackageInfo.fromPlatform();
        packageId = packageInfo.packageName;
        AppLogger.info('[SupabaseService] Package Name en móvil: $packageId');
      }

      String? webUrl;
      if (kIsWeb) {
        webUrl = Uri.base.origin;
        AppLogger.info('[SupabaseService] Web URL origin: $webUrl');
      }

      // Buscar coincidencia en la base de datos
      var query = client.from('channels').select('id');

      if (packageId != null && webUrl != null) {
        query = query.or('android_package_name.eq.$packageId,web_app_url.eq.$webUrl');
      } else if (packageId != null) {
        query = query.eq('android_package_name', packageId);
      } else if (webUrl != null) {
        query = query.eq('web_app_url', webUrl);
      } else {
        AppLogger.info('[SupabaseService] Entorno local sin package ni URL web. Usando canal por defecto.');
        return;
      }

      final response = await query.maybeSingle();

      if (response != null && response['id'] != null) {
        channelId = response['id'] as String;
        AppLogger.info('[SupabaseService] ✅ Canal dinámico resuelto con éxito: $channelId');
      } else {
        AppLogger.warning(
          '[SupabaseService] ⚠️ No se encontró ningún canal vinculado a este entorno en DB. '
          'Usando canal por defecto (fallback): $channelId',
        );
      }
    } catch (e) {
      AppLogger.error('[SupabaseService] ❌ Error resolviendo canal dinámico, usando fallback: $e');
    }
  }

  // ===================================
  // INICIALIZACIÓN
  // ===================================

  /// Inicializa Supabase con las credenciales del .env
  ///
  /// Debe llamarse una sola vez al inicio de la aplicación,
  /// típicamente en main() antes de runApp().
  ///
  /// Retorna true si la inicialización fue exitosa.
  static Future<bool> initialize() async {
    if (_initialized) {
      AppLogger.warning('[Supabase] Ya está inicializado');
      return true;
    }

    try {
      final url = EnvConfig.supabaseUrl;
      final anonKey = EnvConfig.supabaseAnonKey;

      if (url.isEmpty || anonKey.isEmpty) {
        AppLogger.error(
          '[Supabase] Error: Credenciales no configuradas en .env',
        );
        AppLogger.info(
          '   Por favor configura SUPABASE_URL y SUPABASE_ANON_KEY',
        );
        return false;
      }

      AppLogger.info('[Supabase] Inicializando...');
      AppLogger.debug('   URL: $url');

      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
        debug: EnvConfig.debugMode,
        // Configuración de logs en modo debug
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
        ),
        // Configuración de realtime
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
      );

      _initialized = true;
      AppLogger.info('[Supabase] ✅ Inicializado correctamente');
      await resolveChannelId();
      return true;
    } catch (e, stackTrace) {
      AppLogger.error('[Supabase] Error en inicialización', e, stackTrace);
      return false;
    }
  }

  // ===================================
  // TABLAS (Nombres de las tablas en Supabase)
  // ===================================

  /// Nombre de la tabla de programas de TV
  static const String programsTable = 'programs';

  /// Nombre de la tabla de contactos
  static const String contactsTable = 'contacts';

  /// Nombre de la tabla de tokens FCM
  static const String fcmTokensTable = 'fcm_tokens';

  // ===================================
  // HELPERS - PROGRAMACIÓN
  // ===================================

  /// Obtiene la programación de todos los días
  ///
  /// Retorna una lista de todos los programas ordenados por día y hora.
  Future<List<Map<String, dynamic>>> getAllPrograms() async {
    try {
      AppLogger.debug('[Supabase] Obteniendo programación completa para canal: $channelId...');

      final response = await client
          .from(programsTable)
          .select()
          .eq('channel_id', channelId)
          .order('day_of_week')
          .order('start_time');

      AppLogger.info('[Supabase] ✅ Programas obtenidos: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('[Supabase] Error al obtener programación', e);
      rethrow;
    }
  }

  /// Obtiene la programación de un día específico
  ///
  /// [dayOfWeek]: 1 = Lunes, 2 = Martes, ..., 7 = Domingo
  Future<List<Map<String, dynamic>>> getProgramsByDay(int dayOfWeek) async {
    try {
      AppLogger.debug('[Supabase] Obteniendo programas del día $dayOfWeek para canal: $channelId...');

      final response = await client
          .from(programsTable)
          .select()
          .eq('channel_id', channelId)
          .eq('day_of_week', dayOfWeek)
          .order('start_time');

      AppLogger.info('[Supabase] ✅ Programas obtenidos: ${response.length}');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      AppLogger.error('[Supabase] Error al obtener programas del día', e);
      rethrow;
    }
  }

  /// Escucha cambios en tiempo real en la tabla de programas
  ///
  /// Útil para actualizar la UI automáticamente cuando cambia la programación.
  RealtimeChannel subscribeToPrograms(
    void Function(PostgresChangePayload) callback,
  ) {
    AppLogger.debug('[Supabase] Suscribiéndose a cambios en programación para canal: $channelId...');

    return client
        .channel('programs-channel')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: programsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'channel_id',
            value: channelId,
          ),
          callback: callback,
        )
        .subscribe();
  }

  // ===================================
  // HELPERS - CONTACTOS
  // ===================================

  /// Guarda un mensaje de contacto en Supabase
  Future<bool> saveContact({
    required String name,
    required String email,
    required String subject,
    required String message,
  }) async {
    try {
      AppLogger.debug('[Supabase] Guardando mensaje de contacto...');

      await client.from(contactsTable).insert({
        'name': name,
        'email': email,
        'subject': subject,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      });

      AppLogger.info('[Supabase] ✅ Mensaje guardado correctamente');
      return true;
    } catch (e) {
      AppLogger.error('[Supabase] Error al guardar contacto', e);
      return false;
    }
  }

  // ===================================
  // HELPERS - FCM TOKENS
  // ===================================

  /// Guarda un token FCM en Supabase para enviar notificaciones
  Future<bool> saveFcmToken({
    required String token,
    required String platform,
    String? userId,
  }) async {
    try {
      AppLogger.debug('[Supabase] Guardando token FCM...');

      // Primero verificar si ya existe
      final existing = await client
          .from(fcmTokensTable)
          .select()
          .eq('token', token)
          .maybeSingle();

      if (existing != null) {
        // Actualizar token existente
        await client
            .from(fcmTokensTable)
            .update({
              'platform': platform,
              'user_id': userId,
              'channel_id': channelId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('token', token);
      } else {
        // Insertar nuevo token
        await client.from(fcmTokensTable).insert({
          'token': token,
          'platform': platform,
          'user_id': userId,
          'channel_id': channelId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      AppLogger.info('[Supabase] ✅ Token FCM guardado correctamente');
      return true;
    } catch (e) {
      AppLogger.error('[Supabase] Error al guardar token FCM', e);
      return false;
    }
  }

  // ===================================
  // UTILIDADES
  // ===================================

  /// Cierra todas las suscripciones y limpia recursos
  Future<void> dispose() async {
    AppLogger.debug('[Supabase] Limpiando recursos...');
    // Supabase maneja el dispose automáticamente
  }
}
