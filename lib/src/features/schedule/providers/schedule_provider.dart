import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/program_model.dart';
import '../services/schedule_service.dart';
import '../services/local_notification_service.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/supabase_service.dart';

// ===================================
// PROVIDERS
// ===================================

/// Notifier for the selected date
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) => state = date;
}

/// Provider for the selected date
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);

/// Notifier to trigger manual refresh
class ScheduleRefreshNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void refresh() => state++;
}

/// Provider to trigger manual refresh
final scheduleRefreshProvider = NotifierProvider<ScheduleRefreshNotifier, int>(
  ScheduleRefreshNotifier.new,
);

/// Provider for the schedule list based on selected date
/// Now watches the refresh trigger to invalidate cache when needed
final scheduleProvider = FutureProvider.autoDispose
    .family<List<Program>, DateTime>((ref, date) async {
  // Watch refresh trigger to invalidate when it changes
  ref.watch(scheduleRefreshProvider);

  final service = ScheduleService.instance;
  return service.getProgramsForDate(date);
});

/// Provider for Supabase Realtime subscription
/// Listens to changes in the programs table and triggers refresh
/// Also reschedules notifications if a favorite program's time changes
final scheduleRealtimeProvider = StreamProvider.autoDispose((ref) async* {
  try {
    final supabase = ref.read(supabaseClientProvider);

    AppLogger.info('[Realtime] Iniciando suscripción a tabla programs...');

    // Create a realtime channel for programs table
    final channel = supabase
        .channel('programs_changes_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'programs',
          callback: (payload) {
            AppLogger.info(
              '[Realtime] ✅ Cambio detectado en programs: ${payload.eventType}',
            );
            AppLogger.info('[Realtime] Datos: ${payload.newRecord}');

            // Trigger refresh by incrementing the counter
            ref.read(scheduleRefreshProvider.notifier).refresh();

            // If a program was updated, check if it's a favorite and reschedule notifications
            // Check for UPDATE event (could be enum or string)
            final isUpdateEvent = payload.eventType ==
                    PostgresChangeEvent.update ||
                payload.eventType.toString().toLowerCase().contains('update');

            AppLogger.info('[Realtime] Is update event: $isUpdateEvent');
            AppLogger.info(
                '[Realtime] newRecord isEmpty: ${payload.newRecord.isEmpty}');

            if (isUpdateEvent && payload.newRecord.isNotEmpty) {
              final programId = payload.newRecord['id'] as String?;
              AppLogger.info('[Realtime] Program ID from payload: $programId');

              if (programId != null) {
                // Check if this program is in favorites
                // Read directly from SharedPreferences to avoid async loading issues
                SharedPreferences.getInstance().then((prefs) async {
                  final storedFavorites =
                      prefs.getStringList('favorite_programs_ids') ?? [];
                  AppLogger.info(
                      '[Realtime] Favorites from SharedPrefs: $storedFavorites');
                  AppLogger.info(
                      '[Realtime] Is in favorites: ${storedFavorites.contains(programId)}');

                  if (storedFavorites.contains(programId)) {
                    AppLogger.info(
                        '[Realtime] 🔔 Favorite program updated, rescheduling notifications...');

                    // Parse the new program data
                    // NOTE: Supabase Realtime sends time as "15:44:00" not full datetime
                    // We need to construct the full datetime from day_of_week and time
                    try {
                      final record = payload.newRecord;
                      final startTimeStr = record['start_time'] as String;
                      final endTimeStr = record['end_time'] as String;
                      final dayOfWeek = record['day_of_week'] as int;

                      // Parse time parts (format: HH:MM:SS)
                      final startParts = startTimeStr.split(':');
                      final endParts = endTimeStr.split(':');

                      // Calculate the next occurrence of this day of week
                      final now = DateTime.now();
                      int daysUntil = dayOfWeek - now.weekday;
                      if (daysUntil < 0) daysUntil += 7; // Next week
                      final targetDate = now.add(Duration(days: daysUntil));

                      final startTime = DateTime(
                        targetDate.year,
                        targetDate.month,
                        targetDate.day,
                        int.parse(startParts[0]),
                        int.parse(startParts[1]),
                      );
                      final endTime = DateTime(
                        targetDate.year,
                        targetDate.month,
                        targetDate.day,
                        int.parse(endParts[0]),
                        int.parse(endParts[1]),
                      );

                      final updatedProgram = Program(
                        id: record['id'] as String,
                        title: record['title'] as String,
                        description: record['description'] as String? ?? '',
                        startTime: startTime,
                        endTime: endTime,
                        imageUrl: record['image_url'] as String?,
                        isLive: record['is_live'] as bool? ?? false,
                      );

                      AppLogger.info(
                          '[Realtime] Parsed program: ${updatedProgram.title}, startTime: $startTime');

                      // Reschedule notifications with new time
                      await ref
                          .read(favoritesProvider.notifier)
                          .rescheduleNotificationsForProgram(updatedProgram);
                    } catch (e, stackTrace) {
                      AppLogger.error(
                          '[Realtime] Error parsing updated program',
                          e,
                          stackTrace);
                    }
                  }
                });
              }
            }
          },
        )
        .subscribe();

    AppLogger.info('[Realtime] Canal suscrito correctamente');

    // Keep the stream alive
    yield channel;

    // Wait for disposal
    await Future.delayed(const Duration(days: 365));
  } catch (e, stackTrace) {
    AppLogger.error('[Realtime] Error en suscripción', e, stackTrace);
    rethrow;
  }
});

/// Helper provider to get Supabase client
final supabaseClientProvider = Provider((ref) {
  return SupabaseService.client;
});

/// Provider for favorites management
final favoritesProvider = NotifierProvider<FavoritesNotifier, Set<String>>(
  FavoritesNotifier.new,
);

// ===================================
// NOTIFIER
// ===================================

class FavoritesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    _loadFavorites();
    return {};
  }

  static const _prefsKey = 'favorite_programs_ids';

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? stored = prefs.getStringList(_prefsKey);
      if (stored != null) {
        state = stored.toSet();
      }
    } catch (e) {
      AppLogger.error('Error loading favorites from prefs', e);
    }
  }

  Future<void> toggleFavorite(Program program) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationService = LocalNotificationService();

      // Use two different IDs: one for 5-min reminder, one for start time
      final reminder5minId = program.id.hashCode;
      final startTimeId = program.id.hashCode + 1;

      if (state.contains(program.id)) {
        // Remove from favorites
        state = Set.from(state)..remove(program.id);

        // Cancel both notifications
        await notificationService.cancelNotification(reminder5minId);
        await notificationService.cancelNotification(startTimeId);

        AppLogger.info('Canceled notifications for ${program.title}');
      } else {
        // Add to favorites
        state = Set.from(state)..add(program.id);

        final now = DateTime.now();

        // Notification 1: 5 minutes before
        final reminder5min = program.startTime.subtract(
          const Duration(minutes: 5),
        );

        if (reminder5min.isAfter(now)) {
          await notificationService.scheduleNotification(
            id: reminder5minId,
            title: '⏰ ${program.title}',
            body: '¡Tu programa comienza en 5 minutos!',
            scheduledDate: reminder5min,
          );
          AppLogger.info('Scheduled 5-min reminder for ${program.title}');
        }

        // Notification 2: At start time
        if (program.startTime.isAfter(now)) {
          await notificationService.scheduleNotification(
            id: startTimeId,
            title: '🎬 ${program.title}',
            body: '¡Tu programa está comenzando ahora!',
            scheduledDate: program.startTime,
          );
          AppLogger.info('Scheduled start notification for ${program.title}');
        }

        if (reminder5min.isBefore(now) && program.startTime.isBefore(now)) {
          AppLogger.info(
            'Cannot schedule notifications - program already started',
          );
        }
      }

      // Persist favorites
      await prefs.setStringList(_prefsKey, state.toList());
    } catch (e) {
      AppLogger.error('Error toggling favorite', e);
    }
  }

  /// Reschedules notifications for a program when its time changes in Supabase
  Future<void> rescheduleNotificationsForProgram(Program program) async {
    if (!state.contains(program.id)) {
      return; // Not a favorite, nothing to do
    }

    try {
      final notificationService = LocalNotificationService();

      // IDs for the two notifications
      final reminder5minId = program.id.hashCode;
      final startTimeId = program.id.hashCode + 1;

      // Cancel existing notifications
      await notificationService.cancelNotification(reminder5minId);
      await notificationService.cancelNotification(startTimeId);

      final now = DateTime.now();

      // Notification 1: 5 minutes before (with new time)
      final reminder5min = program.startTime.subtract(
        const Duration(minutes: 5),
      );

      if (reminder5min.isAfter(now)) {
        await notificationService.scheduleNotification(
          id: reminder5minId,
          title: '⏰ ${program.title}',
          body: '¡Tu programa comienza en 5 minutos! (Hora actualizada)',
          scheduledDate: reminder5min,
        );
        AppLogger.info(
            '[Realtime] ✅ Rescheduled 5-min reminder for ${program.title}');
      }

      // Notification 2: At new start time
      if (program.startTime.isAfter(now)) {
        await notificationService.scheduleNotification(
          id: startTimeId,
          title: '🎬 ${program.title}',
          body: '¡Tu programa está comenzando ahora!',
          scheduledDate: program.startTime,
        );
        AppLogger.info(
            '[Realtime] ✅ Rescheduled start notification for ${program.title}');
      }
    } catch (e) {
      AppLogger.error('Error rescheduling notifications', e);
    }
  }

  bool isFavorite(String programId) {
    return state.contains(programId);
  }
}
