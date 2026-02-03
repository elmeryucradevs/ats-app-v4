import '../models/contact_message.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/utils/app_logger.dart';

/// Servicio para gestionar mensajes de contacto
class ContactService {
  static final ContactService _instance = ContactService._internal();
  factory ContactService() => _instance;
  ContactService._internal();

  final SupabaseService _supabase = SupabaseService.instance;

  /// Envía un mensaje de contacto
  Future<String> sendMessage(ContactMessage message) async {
    try {
      AppLogger.info('[ContactService] Enviando mensaje de contacto');

      final result = await _supabase.saveContact(
        name: message.name,
        email: message.email,
        subject: message.subject,
        message: message.message,
      );

      if (!result) {
        throw Exception('Error al guardar el mensaje en Supabase');
      }

      AppLogger.info('[ContactService] ✅ Mensaje guardado exitosamente');
      return ''; // Return empty string since we don't have the ID
    } catch (e, stackTrace) {
      AppLogger.error(
        '[ContactService] Error al enviar mensaje',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Valida un email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Valida longitud mínima
  static bool hasMinLength(String text, int minLength) {
    return text.trim().length >= minLength;
  }

  /// Valida longitud máxima
  static bool hasMaxLength(String text, int maxLength) {
    return text.trim().length <= maxLength;
  }
}
