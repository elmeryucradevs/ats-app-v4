/// Modelo de un programa de televisión individual
///
/// Representa un programa en la guía de programación del canal.
/// Incluye título, descripción, horarios y día de la semana.
class Program {
  /// ID único del programa en Supabase
  final String id;

  /// Título del programa
  final String title;

  /// Descripción del programa
  final String description;

  /// Hora de inicio (formato HH:mm)
  final String startTime;

  /// Hora de fin (formato HH:mm)
  final String endTime;

  /// Día de la semana (1 = Lunes, 7 = Domingo)
  final int dayOfWeek;

  /// URL de la imagen/thumbnail del programa
  final String? imageUrl;

  /// Categoría del programa (ej: "Noticias", "Deportes", "Entretenimiento")
  final String? category;

  /// Indica si es un programa recurrente
  final bool isRecurring;

  const Program({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    this.imageUrl,
    this.category,
    this.isRecurring = true,
  });

  /// Crea una copia del programa con algunos campos modificados
  Program copyWith({
    String? id,
    String? title,
    String? description,
    String? startTime,
    String? endTime,
    int? dayOfWeek,
    String? imageUrl,
    String? category,
    bool? isRecurring,
  }) {
    return Program(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  /// Crea un Program desde JSON
  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      dayOfWeek: json['day_of_week'] as int? ?? 1,
      imageUrl: json['image_url'] as String?,
      category: json['category'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? true,
    );
  }

  /// Convierte el Program a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime,
      'end_time': endTime,
      'day_of_week': dayOfWeek,
      'image_url': imageUrl,
      'category': category,
      'is_recurring': isRecurring,
    };
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
        other.dayOfWeek == dayOfWeek &&
        other.imageUrl == imageUrl &&
        other.category == category &&
        other.isRecurring == isRecurring;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      startTime,
      endTime,
      dayOfWeek,
      imageUrl,
      category,
      isRecurring,
    );
  }

  @override
  String toString() {
    return 'Program(id: $id, title: $title, dayOfWeek: $dayOfWeek, timeRange: $timeRange)';
  }

  // ===================================
  // GETTERS Y UTILIDADES
  // ===================================

  /// Obtiene el nombre del día de la semana en español
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

  /// Convierte la hora de inicio a DateTime de hoy
  DateTime get startDateTime {
    final parts = startTime.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Convierte la hora de fin a DateTime de hoy
  DateTime get endDateTime {
    final parts = endTime.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  /// Verifica si el programa está actualmente en vivo
  bool get isLive {
    final now = DateTime.now();
    final currentDay = now.weekday; // 1 = Monday, 7 = Sunday

    if (currentDay != dayOfWeek) return false;

    final start = startDateTime;
    final end = endDateTime;

    return now.isAfter(start) && now.isBefore(end);
  }

  /// Duración del programa en minutos
  int get durationInMinutes {
    return endDateTime.difference(startDateTime).inMinutes;
  }

  /// Formatea el horario como "HH:mm - HH:mm"
  String get timeRange => '$startTime - $endTime';
}
