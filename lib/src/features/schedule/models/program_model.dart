/// Modelo unificado de un programa de televisión
///
/// Representa un programa en la guía de programación del canal.
/// Compatible con ambos sistemas: programación semanal (player) y guía de programas (schedule).
/// Incluye campos adicionales para compatibilidad con el editor de escritorio.
class Program {
  /// ID único del programa en Supabase
  final String id;

  /// Título del programa
  final String title;

  /// Descripción del programa
  final String description;

  /// Hora de inicio (DateTime completo)
  final DateTime startTime;

  /// Hora de fin (DateTime completo)
  final DateTime endTime;

  /// URL de la imagen/thumbnail del programa
  final String? imageUrl;

  /// Indica si el programa está marcado como "en vivo" manualmente
  final bool isLive;

  // ===== Campos adicionales del editor de escritorio =====

  /// Categoría del programa (ej: movies, series, news, sports, etc.)
  final String? category;

  /// Año de lanzamiento del contenido
  final int? releaseYear;

  /// Clasificación del contenido (ej: TV-G, TV-PG, TV-14, etc.)
  final String? contentRating;

  /// Día de la semana almacenado en la base de datos (0=Domingo, 1=Lunes, ..., 6=Sábado)
  final int? storedDayOfWeek;

  /// Nombre del input de vMix asociado
  final String? vmixInputName;

  /// Nombre del presentador/host
  final String? hostName;

  /// Indica si el programa está activo en la programación
  final bool isActive;

  const Program({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.imageUrl,
    this.isLive = false,
    this.category,
    this.releaseYear,
    this.contentRating,
    this.storedDayOfWeek,
    this.vmixInputName,
    this.hostName,
    this.isActive = true,
  });

  /// Verifica si el programa está actualmente en el aire
  bool get isNow {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Día de la semana del programa (1 = Lunes, 7 = Domingo)
  int get dayOfWeek => startTime.weekday;

  /// Nombre del día de la semana en español
  String get dayName {
    const days = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return days[dayOfWeek - 1];
  }

  /// Hora de inicio formateada (HH:mm)
  String get startTimeFormatted {
    return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
  }

  /// Hora de fin formateada (HH:mm)
  String get endTimeFormatted {
    return '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  /// Rango de tiempo formateado (HH:mm - HH:mm)
  String get timeRange => '$startTimeFormatted - $endTimeFormatted';

  /// Duración del programa en minutos
  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Parsea un string de tiempo flexible: ISO8601 o HH:mm:ss
  static DateTime _parseTimeFlexible(String time) {
    // Intentar parsear como ISO8601 primero
    final parsed = DateTime.tryParse(time);
    if (parsed != null) return parsed;

    // Si falla, intentar como HH:mm:ss (usar fecha de hoy)
    final parts = time.split(':');
    if (parts.length >= 2) {
      final now = DateTime.now();
      return DateTime(
        now.year,
        now.month,
        now.day,
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
        parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0,
      );
    }

    // Fallback: usar ahora
    return DateTime.now();
  }

  /// Crea un Program desde JSON (compatible con Supabase)
  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      startTime: _parseTimeFlexible(json['start_time'] as String),
      endTime: _parseTimeFlexible(json['end_time'] as String),
      imageUrl: json['image_url'] as String?,
      isLive: json['is_live'] as bool? ?? false,
      category: json['category'] as String?,
      releaseYear: json['release_year'] as int?,
      contentRating: json['content_rating'] as String?,
      storedDayOfWeek: json['day_of_week'] as int?,
      vmixInputName: json['vmix_input_name'] as String?,
      hostName: json['host_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Convierte el Program a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'image_url': imageUrl,
      'is_live': isLive,
      'category': category,
      'release_year': releaseYear,
      'content_rating': contentRating,
      'day_of_week': storedDayOfWeek,
      'vmix_input_name': vmixInputName,
      'host_name': hostName,
      'is_active': isActive,
    };
  }

  /// Crea una copia del programa con algunos campos modificados
  Program copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? imageUrl,
    bool? isLive,
    String? category,
    int? releaseYear,
    String? contentRating,
    int? storedDayOfWeek,
    String? vmixInputName,
    String? hostName,
    bool? isActive,
  }) {
    return Program(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      imageUrl: imageUrl ?? this.imageUrl,
      isLive: isLive ?? this.isLive,
      category: category ?? this.category,
      releaseYear: releaseYear ?? this.releaseYear,
      contentRating: contentRating ?? this.contentRating,
      storedDayOfWeek: storedDayOfWeek ?? this.storedDayOfWeek,
      vmixInputName: vmixInputName ?? this.vmixInputName,
      hostName: hostName ?? this.hostName,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Program &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.imageUrl == imageUrl &&
        other.isLive == isLive &&
        other.category == category &&
        other.releaseYear == releaseYear &&
        other.contentRating == contentRating &&
        other.storedDayOfWeek == storedDayOfWeek &&
        other.vmixInputName == vmixInputName &&
        other.hostName == hostName &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      startTime,
      endTime,
      imageUrl,
      isLive,
      category,
      releaseYear,
      contentRating,
      storedDayOfWeek,
      vmixInputName,
      hostName,
      isActive,
    );
  }

  @override
  String toString() {
    return 'Program(id: $id, title: $title, dayOfWeek: $dayOfWeek, timeRange: $timeRange, isNow: $isNow)';
  }
}
