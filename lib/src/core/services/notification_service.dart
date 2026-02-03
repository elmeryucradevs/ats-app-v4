import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../utils/app_logger.dart';
import '../services/supabase_service.dart';
import '../config/env_config.dart';
import '../../features/schedule/services/local_notification_service.dart';

/// Handler para mensajes en background
/// IMPORTANTE: Debe ser una función top-level o static
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Inicializar Firebase si no está inicializado
  await Firebase.initializeApp();

  AppLogger.info(
    '[FCM Background] Mensaje recibido: ${message.notification?.title}',
  );
}

/// Servicio de notificaciones push con Firebase Cloud Messaging
///
/// Maneja toda la lógica de notificaciones push incluyendo:
/// - Inicialización de FCM
/// - Obtención y gestión de tokens
/// - Permisos de notificaciones
/// - Suscripción a tópicos
/// - Manejo de mensajes (foreground/background/terminated)
class NotificationService {
  // Singleton
  NotificationService._();
  static final instance = NotificationService._();

  FirebaseMessaging? _messaging;
  String? _fcmToken;

  // Stream controller para notificaciones
  final _messageController = StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onMessage => _messageController.stream;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    try {
      AppLogger.info('[NotificationService] Inicializando FCM...');

      // Verificar si Firebase ya está inicializado
      if (Firebase.apps.isEmpty) {
        AppLogger.warning(
          '[NotificationService] Firebase no inicializado. '
          'Debe inicializarse en main.dart primero.',
        );
        return;
      }

      try {
        _messaging = FirebaseMessaging.instance;

        // Solicitar permisos
        final permissionGranted = await requestPermission();
        if (!permissionGranted) {
          AppLogger.warning(
              '[NotificationService] Permisos de notificación denegados');
          return;
        }
      } catch (e, stackTrace) {
        AppLogger.error('[NotificationService] Error crítico inicializando FCM',
            e, stackTrace);
        // Don't return, allow app to continue without FCM if it fails
      }

      // Obtener y guardar token
      await _getAndSaveToken();

      // Inicializar notificaciones locales
      await LocalNotificationService().initialize();

      // Configurar handlers de mensajes
      _setupMessageHandlers();

      // Suscribirse a tópico general
      await subscribeToTopic('all_users');

      AppLogger.info('[NotificationService] ✅ FCM inicializado correctamente');
    } catch (e, stackTrace) {
      AppLogger.error(
        '[NotificationService] Error al inicializar',
        e,
        stackTrace,
      );
    }
  }

  /// Solicita permisos de notificaciones
  Future<bool> requestPermission() async {
    if (_messaging == null) return false;

    try {
      // En iOS y web, necesitamos solicitar permisos explícitos
      final settings = await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional;

      // También solicitar permisos para notificaciones locales
      await LocalNotificationService().requestPermissions();

      AppLogger.info(
        '[NotificationService] Permisos: '
        '${settings.authorizationStatus.name}',
      );

      return granted;
    } catch (e) {
      AppLogger.error('[NotificationService] Error solicitando permisos', e);
      return false;
    }
  }

  /// Obtiene el token FCM y lo guarda en Supabase
  Future<void> _getAndSaveToken() async {
    if (_messaging == null) return;

    try {
      // En web, necesitamos el VAPID key
      String? token;
      if (kIsWeb) {
        final vapidKey = EnvConfig.firebaseVapidKey;
        if (vapidKey.isNotEmpty) {
          token = await _messaging!.getToken(vapidKey: vapidKey);
        } else {
          AppLogger.warning(
            '[NotificationService] Web: VAPID key no configurado en EnvConfig. '
            'Las notificaciones push no funcionarán en web.',
          );
          return;
        }
      } else {
        token = await _messaging!.getToken();
      }

      if (token != null) {
        _fcmToken = token;
        AppLogger.info('[NotificationService] Token FCM obtenido');

        // Guardar en Supabase
        await _saveTokenToDatabase(token);

        // Listener para cambios de token
        _messaging!.onTokenRefresh.listen((newToken) {
          _fcmToken = newToken;
          _saveTokenToDatabase(newToken);
        });
      }
    } catch (e) {
      AppLogger.error('[NotificationService] Error obteniendo token', e);
    }
  }

  /// Guarda el token en Supabase
  Future<void> _saveTokenToDatabase(String token) async {
    try {
      final supabase = SupabaseService.client;

      // Determinar plataforma
      String platform = 'unknown';
      if (kIsWeb) {
        platform = 'web';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        platform = 'android';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        platform = 'ios';
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        platform = 'windows';
      }

      // Insertar/actualizar token usando el campo 'token' como clave única
      await supabase.from('fcm_tokens').upsert(
        {
          'token': token,
          'platform': platform,
          'last_used_at': DateTime.now().toIso8601String(),
        },
        onConflict:
            'token', // Usa 'token' como campo único para detectar duplicados
      );

      AppLogger.info('[NotificationService] Token guardado en Supabase');
    } catch (e) {
      AppLogger.error('[NotificationService] Error guardando token en DB', e);
    }
  }

  /// Configura los handlers de mensajes
  void _setupMessageHandlers() {
    if (_messaging == null) return;

    // Handler para mensajes en foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info(
        '[FCM Foreground] Mensaje: ${message.notification?.title}',
      );
      _messageController.add(message);
      _handleForegroundMessage(message);
    });

    // Handler para cuando el usuario toca la notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info('[FCM Opened] Mensaje: ${message.notification?.title}');
      _handleMessageOpenedApp(message);
    });

    // Handler para mensajes en background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Verificar si la app se abrió desde una notificación
    _checkInitialMessage();
  }

  /// Verifica si la app se abrió desde una notificación
  Future<void> _checkInitialMessage() async {
    if (_messaging == null) return;

    try {
      final message = await _messaging!.getInitialMessage();
      if (message != null) {
        AppLogger.info(
          '[FCM Initial] App abierta desde notificación: '
          '${message.notification?.title}',
        );
        _handleMessageOpenedApp(message);
      }
    } catch (e) {
      AppLogger.error(
        '[NotificationService] Error checking initial message',
        e,
      );
    }
  }

  /// Maneja mensajes recibidos en foreground
  void _handleForegroundMessage(RemoteMessage message) {
    if (message.notification != null) {
      LocalNotificationService().showNotification(
        id: message.messageId.hashCode,
        title: message.notification!.title ?? 'Notificación',
        body: message.notification!.body ?? '',
      );
    }

    AppLogger.info(
      '[NotificationService] Foreground message: '
      'title=${message.notification?.title}, '
      'body=${message.notification?.body}',
    );
  }

  /// Maneja cuando el usuario toca una notificación
  void _handleMessageOpenedApp(RemoteMessage message) {
    // La navegación se manejará en un provider separado
    // que escucha el stream onMessage
    AppLogger.info(
      '[NotificationService] User tapped notification: '
      'data=${message.data}',
    );
  }

  /// Suscribirse a un tópico
  Future<void> subscribeToTopic(String topic) async {
    if (_messaging == null) return;

    try {
      await _messaging!.subscribeToTopic(topic);
      AppLogger.info('[NotificationService] Suscrito a tópico: $topic');
    } catch (e) {
      AppLogger.error('[NotificationService] Error suscribirse a $topic', e);
    }
  }

  /// Desuscribirse de un tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_messaging == null) return;

    try {
      await _messaging!.unsubscribeFromTopic(topic);
      AppLogger.info('[NotificationService] Desuscrito de tópico: $topic');
    } catch (e) {
      AppLogger.error('[NotificationService] Error desuscribirse de $topic', e);
    }
  }

  /// Obtiene el token FCM actual
  String? get token => _fcmToken;

  /// Libera recursos
  void dispose() {
    _messageController.close();
  }
}
