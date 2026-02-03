import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_logger.dart';
import '../models/program.dart';

/// Servicio para gestionar la programación del canal
///
/// Obtiene y cachea la programación desde Supabase,
/// detecta el programa actual en vivo.
class ScheduleService {
  ScheduleService._();

  /// Instancia única del servicio
  static final ScheduleService instance = ScheduleService._();

  /// Cache de programas
  List<Program>? _cachedPrograms;

  /// Timestamp del último fetch
  DateTime? _lastFetch;

  /// Duración del cache (5 minutos)
  static const Duration _cacheDuration = Duration(minutes: 5);

  // ===================================
  // OBTENER PROGRAMACIÓN
  // ===================================

  /// Obtiene todos los programas de la semana
  ///
  /// Usa cache si está disponible y no ha expirado
  Future<List<Program>> getAllPrograms({bool forceRefresh = false}) async {
    try {
      // Verificar si el cache es válido
      if (!forceRefresh && _isCacheValid()) {
        AppLogger.debug('[Schedule] Usando programas cacheados');
        return _cachedPrograms!;
      }

      AppLogger.info('[Schedule] Obteniendo programación desde Supabase...');

      // Obtener desde Supabase
      final response = await SupabaseService.instance.getAllPrograms();

      // Convertir a modelos Program
      final programs = response.map((json) => Program.fromJson(json)).toList();

      // Actualizar cache
      _cachedPrograms = programs;
      _lastFetch = DateTime.now();

      AppLogger.info('[Schedule] ✅ ${programs.length} programas obtenidos');
      return programs;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[Schedule] Error al obtener programación',
        e,
        stackTrace,
      );

      // Retornar cache si existe, aunque esté expirado
      if (_cachedPrograms != null) {
        AppLogger.warning('[Schedule] Usando cache expirado como fallback');
        return _cachedPrograms!;
      }

      return [];
    }
  }

  /// Obtiene los programas de un día específico
  ///
  /// [dayOfWeek]: 1 = Lunes, 7 = Domingo
  Future<List<Program>> getProgramsByDay(int dayOfWeek) async {
    try {
      AppLogger.debug('[Schedule] Obteniendo programas del día $dayOfWeek');

      final response = await SupabaseService.instance.getProgramsByDay(
        dayOfWeek,
      );

      final programs = response.map((json) => Program.fromJson(json)).toList();

      AppLogger.info(
        '[Schedule] ✅ ${programs.length} programas obtenidos para el día $dayOfWeek',
      );
      return programs;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[Schedule] Error al obtener programas del día',
        e,
        stackTrace,
      );
      return [];
    }
  }

  // ===================================
  // PROGRAMA ACTUAL
  // ===================================

  /// Obtiene el programa que está actualmente en vivo
  ///
  /// Retorna null si no hay ningún programa en vivo
  Future<Program?> getCurrentProgram() async {
    try {
      final now = DateTime.now();
      final currentDay = now.weekday; // 1 = Monday, 7 = Sunday

      AppLogger.debug(
        '[Schedule] Buscando programa actual (día: $currentDay, hora: ${now.hour}:${now.minute})',
      );

      // Obtener todos los programas
      final allPrograms = await getAllPrograms();

      // Filtrar programas del día actual
      final todayPrograms = allPrograms
          .where((p) => p.dayOfWeek == currentDay)
          .toList();

      // Buscar el programa que está en vivo
      for (final program in todayPrograms) {
        if (program.isLive) {
          AppLogger.info('[Schedule] ✅ Programa actual: ${program.title}');
          return program;
        }
      }

      AppLogger.warning('[Schedule] No hay programa en vivo actualmente');
      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[Schedule] Error al obtener programa actual',
        e,
        stackTrace,
      );
      return null;
    }
  }

  /// Obtiene el próximo programa que se transmitirá
  Future<Program?> getNextProgram() async {
    try {
      final now = DateTime.now();
      final currentDay = now.weekday;

      final allPrograms = await getAllPrograms();

      // Filtrar programas del día actual que aún no han empezado
      final upcomingToday = allPrograms
          .where(
            (p) => p.dayOfWeek == currentDay && p.startDateTime.isAfter(now),
          )
          .toList();

      if (upcomingToday.isNotEmpty) {
        // Ordenar por hora de inicio y tomar el primero
        upcomingToday.sort(
          (a, b) => a.startDateTime.compareTo(b.startDateTime),
        );
        final nextProgram = upcomingToday.first;

        AppLogger.info(
          '[Schedule] ✅ Próximo programa: ${nextProgram.title} a las ${nextProgram.startTime}',
        );
        return nextProgram;
      }

      // Si no hay más programas hoy, buscar el primero de mañana
      final tomorrowDay = (currentDay % 7) + 1;
      final tomorrowPrograms = allPrograms
          .where((p) => p.dayOfWeek == tomorrowDay)
          .toList();

      if (tomorrowPrograms.isNotEmpty) {
        tomorrowPrograms.sort(
          (a, b) => a.startDateTime.compareTo(b.startDateTime),
        );
        return tomorrowPrograms.first;
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[Schedule] Error al obtener próximo programa',
        e,
        stackTrace,
      );
      return null;
    }
  }

  // ===================================
  // CACHE
  // ===================================

  /// Verifica si el cache es válido
  bool _isCacheValid() {
    if (_cachedPrograms == null || _lastFetch == null) {
      return false;
    }

    final cacheAge = DateTime.now().difference(_lastFetch!);
    return cacheAge < _cacheDuration;
  }

  /// Limpia el cache
  void clearCache() {
    AppLogger.debug('[Schedule] Limpiando cache');
    _cachedPrograms = null;
    _lastFetch = null;
  }
}
