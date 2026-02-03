import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';

/// Widget para mostrar una notificación individual
class NotificationCard extends StatelessWidget {
  const NotificationCard({
    required this.notification,
    this.isUnread = false,
    this.onTap,
    this.onDismiss,
    super.key,
  });

  final RemoteMessage notification;
  final bool isUnread;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.messageId ?? DateTime.now().toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppConstants.spacingMd),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        elevation: isUnread ? 2 : 1,
        color: isUnread
            ? Theme.of(
                context,
              ).colorScheme.primaryContainer.withAlpha((0.1 * 255).round())
            : null,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMd),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono según tipo
                _buildIcon(context),
                const SizedBox(width: AppConstants.spacingMd),

                // Contenido
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título e indicador no leído
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.notification?.title ??
                                  'Notificación',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: isUnread
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                  ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isUnread) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Cuerpo del mensaje
                      if (notification.notification?.body != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          notification.notification!.body!,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.grey[600]),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      // Timestamp
                      const SizedBox(height: 8),
                      Text(
                        _getTimeAgo(notification.sentTime),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(BuildContext context) {
    // Detectar tipo de notificación desde los datos
    final type = notification.data['type'] as String?;

    IconData icon;
    Color color;

    switch (type) {
      case 'program':
        icon = Icons.live_tv;
        color = Colors.red;
        break;
      case 'news':
        icon = Icons.article;
        color = Colors.blue;
        break;
      default:
        icon = Icons.notifications;
        color = Theme.of(context).colorScheme.primary;
    }

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingSm),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(AppConstants.radiusSm),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  String _getTimeAgo(DateTime? sentTime) {
    if (sentTime == null) return 'Ahora';

    final now = DateTime.now();
    final difference = now.difference(sentTime);

    if (difference.inSeconds < 60) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays}d';
    } else {
      return DateFormat('dd/MM/yyyy').format(sentTime);
    }
  }
}
