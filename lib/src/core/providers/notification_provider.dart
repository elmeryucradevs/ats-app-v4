import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/notification_service.dart';
import '../utils/app_logger.dart';

/// Estado de las notificaciones
class NotificationState {
  final bool hasPermission;
  final String? fcmToken;
  final List<RemoteMessage> notifications;
  final int unreadCount;

  const NotificationState({
    this.hasPermission = false,
    this.fcmToken,
    this.notifications = const [],
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    bool? hasPermission,
    String? fcmToken,
    List<RemoteMessage>? notifications,
    int? unreadCount,
  }) {
    return NotificationState(
      hasPermission: hasPermission ?? this.hasPermission,
      fcmToken: fcmToken ?? this.fcmToken,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

/// Notifier para gestionar el estado de notificaciones
class NotificationNotifier extends Notifier<NotificationState> {
  final _service = NotificationService.instance;

  @override
  NotificationState build() {
    // Escuchar mensajes entrantes
    final subscription = _service.onMessage.listen((message) {
      AppLogger.info(
        '[NotificationProvider] Nuevo mensaje: ${message.notification?.title}',
      );

      // Agregar mensaje a la lista
      final updatedNotifications = [message, ...state.notifications];

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: state.unreadCount + 1,
      );
    });

    // Cancelar suscripción al eliminar el provider
    ref.onDispose(subscription.cancel);

    // Obtener token si existe
    final token = _service.token;

    // Inicializar estado con el token si existe, o valores por defecto
    return NotificationState(
      fcmToken: token,
      // Los demás campos usan sus valores por defecto (defined in class)
    );
  }

  /// Actualiza el estado de permisos
  void updatePermissionStatus(bool granted) {
    state = state.copyWith(hasPermission: granted);
    AppLogger.info('[NotificationProvider] Permisos: $granted');
  }

  /// Actualiza el token FCM
  void updateToken(String token) {
    state = state.copyWith(fcmToken: token);
    AppLogger.info('[NotificationProvider] Token actualizado');
  }

  /// Marca todas las notificaciones como leídas
  void markAllAsRead() {
    state = state.copyWith(unreadCount: 0);
    AppLogger.info('[NotificationProvider] Todas marcadas como leídas');
  }

  /// Elimina una notificación
  void removeNotification(int index) {
    if (index < 0 || index >= state.notifications.length) return;

    final updatedNotifications = List<RemoteMessage>.from(state.notifications)
      ..removeAt(index);

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
    );

    AppLogger.info('[NotificationProvider] Notificación eliminada');
  }

  /// Limpia todas las notificaciones
  void clearAll() {
    state = const NotificationState();
    AppLogger.info(
      '[NotificationProvider] Todas las notificaciones eliminadas',
    );
  }

  /// Suscribirse a un tópico
  Future<void> subscribeToTopic(String topic) async {
    await _service.subscribeToTopic(topic);
  }

  /// Desuscribirse de un tópico
  Future<void> unsubscribeFromTopic(String topic) async {
    await _service.unsubscribeFromTopic(topic);
  }
}

/// Provider del estado de notificaciones
final notificationProvider =
    NotifierProvider<NotificationNotifier, NotificationState>(() {
      return NotificationNotifier();
    });

/// Provider para obtener solo notificaciones no leídas
final unreadNotificationsProvider = Provider<List<RemoteMessage>>((ref) {
  final state = ref.watch(notificationProvider);
  // Retornar las primeras 'unreadCount' notificaciones
  return state.notifications.take(state.unreadCount).toList();
});

/// Provider para verificar si hay notificaciones no leídas
final hasUnreadNotificationsProvider = Provider<bool>((ref) {
  final state = ref.watch(notificationProvider);
  return state.unreadCount > 0;
});
