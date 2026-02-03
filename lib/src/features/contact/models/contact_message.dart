/// Modelo para un mensaje de contacto
///
/// Representa un mensaje enviado a través del formulario de contacto.
class ContactMessage {
  /// ID del mensaje (generado por Supabase)
  final String? id;

  /// Nombre del remitente
  final String name;

  /// Email del remitente
  final String email;

  /// Asunto del mensaje
  final String subject;

  /// Contenido del mensaje
  final String message;

  /// Fecha de creación (generada por Supabase)
  final DateTime? createdAt;

  /// Si el mensaje ya fue leído
  final bool isRead;

  const ContactMessage({
    this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    this.createdAt,
    this.isRead = false,
  });

  /// Crea un ContactMessage desde JSON de Supabase
  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['id'] as String?,
      name: json['name'] as String,
      email: json['email'] as String,
      subject: json['subject'] as String,
      message: json['message'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isRead: json['is_read'] as bool? ?? false,
    );
  }

  /// Convierte el ContactMessage a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      'is_read': isRead,
    };
  }

  /// Copia el mensaje con algunos campos modificados
  ContactMessage copyWith({
    String? id,
    String? name,
    String? email,
    String? subject,
    String? message,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return ContactMessage(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  String toString() =>
      'ContactMessage(name: $name, email: $email, subject: $subject)';
}
