import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/contact_service.dart';
import '../models/contact_message.dart';

/// Estados del formulario de contacto
enum ContactFormStatus { initial, sending, success, error }

/// Estado del formulario de contacto
class ContactFormState {
  final ContactFormStatus status;
  final String? errorMessage;

  const ContactFormState({
    this.status = ContactFormStatus.initial,
    this.errorMessage,
  });

  ContactFormState copyWith({ContactFormStatus? status, String? errorMessage}) {
    return ContactFormState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }
}

/// Notifier para el estado del formulario de contacto
class ContactFormNotifier extends Notifier<ContactFormState> {
  late final ContactService _contactService;

  @override
  ContactFormState build() {
    _contactService = ref.watch(contactServiceProvider);
    return const ContactFormState();
  }

  /// Envía un mensaje de contacto
  Future<void> sendMessage(ContactMessage message) async {
    state = state.copyWith(status: ContactFormStatus.sending);

    try {
      await _contactService.sendMessage(message);
      state = state.copyWith(status: ContactFormStatus.success);
    } catch (e) {
      state = state.copyWith(
        status: ContactFormStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Resetea el formulario al estado inicial
  void reset() {
    state = const ContactFormState();
  }
}

/// Provider del servicio de contacto
final contactServiceProvider = Provider<ContactService>((ref) {
  return ContactService();
});

/// Provider del estado del formulario
final contactFormProvider =
    NotifierProvider<ContactFormNotifier, ContactFormState>(() {
      return ContactFormNotifier();
    });
