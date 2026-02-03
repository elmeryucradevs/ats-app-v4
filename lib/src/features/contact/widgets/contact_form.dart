import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/contact_message.dart';
import '../providers/contact_provider.dart';
import '../services/contact_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';
import '../../../core/services/platform_service.dart';

/// Formulario de contacto con validaciones
class ContactForm extends ConsumerStatefulWidget {
  const ContactForm({super.key});

  @override
  ConsumerState<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends ConsumerState<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(contactFormProvider);
    final isTv = ref.watch(isTvProvider);

    // Mostrar éxito y resetear form
    if (formState.status == ContactFormStatus.success) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mensaje enviado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _formKey.currentState?.reset();
        _nameController.clear();
        _emailController.clear();
        _subjectController.clear();
        _messageController.clear();
        ref.read(contactFormProvider.notifier).reset();
      });
    }

    // Mostrar error
    if (formState.status == ContactFormStatus.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${formState.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
        ref.read(contactFormProvider.notifier).reset();
      });
    }

    final isSending = formState.status == ContactFormStatus.sending;

    // En modo TV, usar campos TVTextField
    if (isTv) {
      return _buildTvForm(isSending);
    }

    // Modo normal
    return _buildNormalForm(isSending);
  }

  Widget _buildTvForm(bool isSending) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TVTextField(
            id: 'contact_form_name',
            controller: _nameController,
            upId: 'contact_whatsapp',
            downId: 'contact_form_email',
            leftId: 'nav_4',
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Tu nombre completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
            enabled: !isSending,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es requerido';
              }
              if (!ContactService.hasMinLength(value, 3)) {
                return 'El nombre debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),
          TVTextField(
            id: 'contact_form_email',
            controller: _emailController,
            upId: 'contact_form_name',
            downId: 'contact_form_subject',
            leftId: 'nav_4',
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'tucorreo@ejemplo.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !isSending,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El email es requerido';
              }
              if (!ContactService.isValidEmail(value)) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),
          TVTextField(
            id: 'contact_form_subject',
            controller: _subjectController,
            upId: 'contact_form_email',
            downId: 'contact_form_message',
            leftId: 'nav_4',
            decoration: const InputDecoration(
              labelText: 'Asunto',
              hintText: 'Tema de tu mensaje',
              prefixIcon: Icon(Icons.subject_outlined),
            ),
            enabled: !isSending,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El asunto es requerido';
              }
              if (!ContactService.hasMinLength(value, 5)) {
                return 'El asunto debe tener al menos 5 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),
          TVTextField(
            id: 'contact_form_message',
            controller: _messageController,
            upId: 'contact_form_subject',
            downId: 'contact_form_submit',
            leftId: 'nav_4',
            decoration: const InputDecoration(
              labelText: 'Mensaje',
              hintText: 'Escribe tu mensaje aquí...',
              prefixIcon: Icon(Icons.message_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            enabled: !isSending,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El mensaje es requerido';
              }
              if (!ContactService.hasMinLength(value, 20)) {
                return 'El mensaje debe tener al menos 20 caracteres';
              }
              if (!ContactService.hasMaxLength(value, 1000)) {
                return 'El mensaje no puede exceder 1000 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingLg),
          SizedBox(
            height: 50,
            child: TVButton(
              id: 'contact_form_submit',
              upId: 'contact_form_message',
              downId: 'mini_banner', // Conectar al MiniPlayer
              leftId: 'nav_4',
              onPressed: isSending ? null : _submitForm,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSending)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.send),
                  const SizedBox(width: 8),
                  Text(isSending ? 'Enviando...' : 'Enviar Mensaje'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNormalForm(bool isSending) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre',
              hintText: 'Tu nombre completo',
              prefixIcon: Icon(Icons.person_outline),
            ),
            enabled: !isSending,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es requerido';
              }
              if (!ContactService.hasMinLength(value, 3)) {
                return 'El nombre debe tener al menos 3 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'tucorreo@ejemplo.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !isSending,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El email es requerido';
              }
              if (!ContactService.isValidEmail(value)) {
                return 'Email inválido';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),
          TextFormField(
            controller: _subjectController,
            decoration: const InputDecoration(
              labelText: 'Asunto',
              hintText: 'Tema de tu mensaje',
              prefixIcon: Icon(Icons.subject_outlined),
            ),
            enabled: !isSending,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El asunto es requerido';
              }
              if (!ContactService.hasMinLength(value, 5)) {
                return 'El asunto debe tener al menos 5 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingMd),
          TextFormField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: 'Mensaje',
              hintText: 'Escribe tu mensaje aquí...',
              prefixIcon: Icon(Icons.message_outlined),
              alignLabelWithHint: true,
            ),
            maxLines: 5,
            enabled: !isSending,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El mensaje es requerido';
              }
              if (!ContactService.hasMinLength(value, 20)) {
                return 'El mensaje debe tener al menos 20 caracteres';
              }
              if (!ContactService.hasMaxLength(value, 1000)) {
                return 'El mensaje no puede exceder 1000 caracteres';
              }
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spacingLg),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isSending ? null : _submitForm,
              icon: isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(isSending ? 'Enviando...' : 'Enviar Mensaje'),
            ),
          ),
        ],
      ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final message = ContactMessage(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      );

      ref.read(contactFormProvider.notifier).sendMessage(message);
    }
  }
}
