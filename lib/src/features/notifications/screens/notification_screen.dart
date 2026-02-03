import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/notification_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../widgets/notification_card.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';

/// Pantalla para ver historial de notificaciones
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _showOnlyUnread = false;

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final notifications = _showOnlyUnread
        ? ref.watch(unreadNotificationsProvider)
        : notificationState.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          // Filtro de no leídas
          IconButton(
            icon: Icon(
              _showOnlyUnread ? Icons.filter_list_off : Icons.filter_list,
            ),
            tooltip: _showOnlyUnread ? 'Mostrar todas' : 'Solo no leídas',
            onPressed: () {
              setState(() {
                _showOnlyUnread = !_showOnlyUnread;
              });
            },
          ),
          // Marcar todas como leídas
          if (notificationState.unreadCount > 0)
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Marcar todas como leídas',
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todas marcadas como leídas'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          // Eliminar todas
          if (notifications.isNotEmpty)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'clear') {
                  _showClearDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20),
                      SizedBox(width: 8),
                      Text('Eliminar todas'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(notifications),
    );
  }

  Widget _buildBody(List notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Refresh - en este caso solo mostramos un mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notificaciones actualizadas'),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final isUnread = index < ref.read(notificationProvider).unreadCount;

          return NotificationCard(
            notification: notification,
            isUnread: isUnread,
            onTap: () => _handleNotificationTap(notification),
            onDismiss: () => _removeNotification(index),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _showOnlyUnread
                ? Icons.notifications_off
                : Icons.notifications_none,
            size: AppConstants.iconSizeXl * 2,
            color: Colors.grey,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            _showOnlyUnread
                ? 'No hay notificaciones sin leer'
                : 'No hay notificaciones',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: AppConstants.spacingSm),
          Text(
            'Las notificaciones aparecerán aquí',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(RemoteMessage notification) {
    final data = notification.data;

    // Si no hay datos, mostrar diálogo
    if (data.isEmpty) {
      _showNotificationDialog(notification);
      return;
    }

    // Lógica de navegación basada en 'type' o 'route'
    final type = data['type'] as String?;
    final postId = data['postId'] ?? data['id'];

    if (type == 'news_detail' && postId != null) {
      context.pushNamed(
        'newsDetail',
        pathParameters: {'id': postId.toString()},
      );
    } else if (type == 'news') {
      context.goNamed('news');
    } else if (type == 'social') {
      context.goNamed('social');
    } else if (type == 'contact') {
      context.goNamed('contact');
    } else {
      // Si no coincide con ninguna ruta conocida, mostrar el diálogo con los datos
      _showNotificationDialog(notification);
    }
  }

  void _showNotificationDialog(RemoteMessage notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.notification?.title ?? 'Notificación'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (notification.notification?.body != null) ...[
                Text(notification.notification!.body!),
                const SizedBox(height: 16),
              ],
              if (notification.data.isNotEmpty) ...[
                const Text(
                  'Datos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(notification.data.toString()),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _removeNotification(int index) {
    ref.read(notificationProvider.notifier).removeNotification(index);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificación eliminada'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar todas'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar todas las notificaciones?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              ref.read(notificationProvider.notifier).clearAll();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Todas las notificaciones eliminadas'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
