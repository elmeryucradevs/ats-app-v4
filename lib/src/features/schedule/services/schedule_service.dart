import '../models/program_model.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/services/supabase_service.dart';

class ScheduleService {
  // Singleton
  ScheduleService._();
  static final instance = ScheduleService._();

  /// Obtiene los programas para una fecha específica desde Supabase
  /// La base de datos usa day_of_week (0-6) donde 0 = Domingo
  Future<List<Program>> getProgramsForDate(DateTime date) async {
    try {
      final supabase = SupabaseService.client;

      // Calcular el día de la semana (0 = Domingo, 1 = Lunes, etc.)
      // DateTime.weekday usa 1-7 donde 1 = Lunes, 7 = Domingo
      // Necesitamos convertir a 0-6 donde 0 = Domingo
      final dayOfWeek =
          date.weekday % 7; // Convierte 7 (Domingo) a 0, mantiene 1-6

      AppLogger.info(
        'Fetching programs for ${_getDayName(dayOfWeek)} (day_of_week: $dayOfWeek)',
      );

      // Consultar programas para este día de la semana
      final response = await supabase
          .from('programs')
          .select()
          .eq('day_of_week', dayOfWeek)
          .eq('is_active', true)
          .order('start_time', ascending: true);

      AppLogger.info('Received ${response.length} programs from Supabase');

      // Convertir resultados a objetos Program
      // Necesitamos combinar la fecha del día solicitado con la hora del programa
      final programs = (response as List).map((json) {
        final map = json as Map<String, dynamic>;

        // Parsear la hora (formato TIME de PostgreSQL: "HH:MM:SS")
        final startTimeParts = (map['start_time'] as String).split(':');
        final endTimeParts = (map['end_time'] as String).split(':');

        // Crear DateTime completos combinando la fecha solicitada con las horas
        final startTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(startTimeParts[0]),
          int.parse(startTimeParts[1]),
          int.parse(
            startTimeParts[2].split('.')[0],
          ), // Remover microsegundos si existen
        );

        final endTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(endTimeParts[0]),
          int.parse(endTimeParts[1]),
          int.parse(endTimeParts[2].split('.')[0]),
        );

        // Crear el objeto Program con los datos de Supabase
        return Program(
          id: map['id'] as String,
          title: map['title'] as String,
          description: map['description'] as String? ?? '',
          startTime: startTime,
          endTime: endTime,
          imageUrl: map['image_url'] as String?,
          isLive: map['is_live'] as bool? ?? false,
        );
      }).toList();

      return programs;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching programs from Supabase', e, stackTrace);
      return [];
    }
  }

  /// Obtiene los programas de un día específico de la semana (1-7)
  /// Compatible con el formato del player: 1 = Lunes, 7 = Domingo
  Future<List<Program>> getProgramsByDay(int dayOfWeek) async {
    // Crear una fecha de ejemplo para ese día de la semana
    final now = DateTime.now();
    final today = now.weekday;
    final daysToAdd = (dayOfWeek - today) % 7;
    final targetDate = now.add(Duration(days: daysToAdd));

    return getProgramsForDate(targetDate);
  }

  /// Obtiene todos los programas de la semana
  Future<List<Program>> getAllPrograms() async {
    try {
      final allPrograms = <Program>[];

      // Obtener programas para los próximos 7 días
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        final dayPrograms = await getProgramsForDate(date);
        allPrograms.addAll(dayPrograms);
      }

      return allPrograms;
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching all programs', e, stackTrace);
      return [];
    }
  }

  /// Obtiene el programa que está actualmente en vivo
  Future<Program?> getCurrentProgram() async {
    try {
      final now = DateTime.now();
      final todayPrograms = await getProgramsForDate(now);

      // Buscar el programa que está en el aire ahora mismo
      for (final program in todayPrograms) {
        if (program.isNow) {
          AppLogger.info('Current program: ${program.title}');
          return program;
        }
      }

      AppLogger.info('No program currently live');
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting current program', e, stackTrace);
      return null;
    }
  }

  /// Obtiene el próximo programa que se transmitirá
  Future<Program?> getNextProgram() async {
    try {
      final now = DateTime.now();
      final todayPrograms = await getProgramsForDate(now);

      // Buscar el primer programa que empiece después de ahora
      for (final program in todayPrograms) {
        if (program.startTime.isAfter(now)) {
          AppLogger.info(
            'Next program: ${program.title} at ${program.startTimeFormatted}',
          );
          return program;
        }
      }

      // Si no hay más programas hoy, buscar mañana
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowPrograms = await getProgramsForDate(tomorrow);

      if (tomorrowPrograms.isNotEmpty) {
        return tomorrowPrograms.first;
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Error getting next program', e, stackTrace);
      return null;
    }
  }

  /// Helper para obtener el nombre del día en español
  String _getDayName(int dayOfWeek) {
    const days = [
      'Domingo',
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
    ];
    return days[dayOfWeek];
  }
}
