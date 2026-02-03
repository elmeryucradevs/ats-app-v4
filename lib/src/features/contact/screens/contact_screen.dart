import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/contact_form.dart';
import '../../../core/services/config_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';

/// Pantalla de contacto
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch App Config for realtime updates
    final config = ref.watch(configServiceProvider);

    final items = <_ContactItem>[];

    // Email
    if (config.showEmail && (config.contactEmail?.isNotEmpty ?? false)) {
      items.add(_ContactItem(
        id: 'contact_email',
        icon: Icons.email_outlined,
        title: 'Email',
        subtitle: config.contactEmail!,
        onTap: () => _launchEmail(config.contactEmail!),
      ));
    }

    // WhatsApp
    if (config.showWhatsapp && (config.whatsappNumber?.isNotEmpty ?? false)) {
      items.add(_ContactItem(
        id: 'contact_whatsapp',
        icon: Icons.phone_android,
        title: 'WhatsApp',
        subtitle: config.whatsappNumber!,
        onTap: () => _launchUrl('https://wa.me/${config.whatsappNumber}'),
      ));
    }

    // Website (Requested by user)
    if (config.showWebsite && (config.websiteUrl?.isNotEmpty ?? false)) {
      items.add(_ContactItem(
        id: 'contact_website',
        icon: Icons.language,
        title: 'Sitio Web',
        subtitle: config.websiteUrl!,
        onTap: () => _launchUrl(config.websiteUrl!),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Contacto')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Contáctanos',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Envíanos un mensaje y te responderemos lo antes posible',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: AppConstants.spacingXl),

            // Información de contacto con TVListTile
            if (items.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.spacingMd),
                  child: Column(
                    children: [
                      for (int i = 0; i < items.length; i++)
                        TVListTile(
                          id: items[i].id,
                          leftId: 'nav_4', // Volver al sidebar
                          upId: i > 0 ? items[i - 1].id : null,
                          downId: i < items.length - 1
                              ? items[i + 1].id
                              : 'contact_form_name', // Último va al Form
                          leading: Icon(items[i].icon),
                          title: Text(items[i].title),
                          subtitle: Text(items[i].subtitle),
                          onTap: items[i].onTap,
                        ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: AppConstants.spacingXl),

            // Formulario
            const ContactForm(),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail(String email) async {
    final url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}

class _ContactItem {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _ContactItem({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
