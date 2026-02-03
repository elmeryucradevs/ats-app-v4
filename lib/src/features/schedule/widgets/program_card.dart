import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/program_model.dart';
import '../providers/schedule_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';

class ProgramCard extends ConsumerWidget {
  final Program program;

  // TV Navigation IDs
  final String? tvId;
  final String? tvUpId;
  final String? tvDownId;
  final String? tvLeftId;
  final String? tvRightId;

  const ProgramCard({
    super.key,
    required this.program,
    this.tvId,
    this.tvUpId,
    this.tvDownId,
    this.tvLeftId,
    this.tvRightId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch favorites state
    final favorites = ref.watch(favoritesProvider);
    final isFavorite = favorites.contains(program.id);

    final timeFormat = DateFormat('HH:mm');
    final isNow = program.isNow;

    final cardContent = Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          Column(
            children: [
              Text(
                timeFormat.format(program.startTime),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                width: 2,
                height: 20,
                color: Colors.grey.withOpacity(0.3),
                margin: const EdgeInsets.symmetric(vertical: 4),
              ),
              Text(
                timeFormat.format(program.endTime),
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Info Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (program.isLive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'EN VIVO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (isNow)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AHORA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        program.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  program.description,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action Button
          IconButton(
            icon: Icon(
              isFavorite
                  ? Icons.notifications_active
                  : Icons.notifications_none,
              color: isFavorite ? AppColors.accent : Colors.grey,
            ),
            onPressed: () {
              ref.read(favoritesProvider.notifier).toggleFavorite(program);

              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isFavorite
                        ? 'Recordatorio eliminado'
                        : 'Recordatorio programado para 10 min antes',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );

    // Si tiene TV ID, usar TVCard para navegación
    if (tvId != null) {
      return TVCard(
        id: tvId!,
        upId: tvUpId,
        downId: tvDownId,
        leftId: tvLeftId,
        rightId: tvRightId,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isNow ? AppColors.accent.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(12),
            border:
                isNow ? Border.all(color: AppColors.accent, width: 2) : null,
          ),
          child: cardContent,
        ),
      );
    }

    // Fallback a Card normal si no hay TV ID
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isNow ? 4 : 1,
      color: isNow ? AppColors.accent.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isNow
            ? const BorderSide(color: AppColors.accent, width: 2)
            : BorderSide.none,
      ),
      child: cardContent,
    );
  }
}
