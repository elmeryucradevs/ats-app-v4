import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/social_link.dart';
import '../widgets/social_card.dart';
import '../../../core/services/config_service.dart';
import '../../../core/constants/app_constants.dart';

/// Pantalla de redes sociales
class SocialScreen extends ConsumerWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch App Configuration
    final config = ref.watch(configServiceProvider);

    // Build Social Links based on Config
    final socialLinks = [
      if (config.showWebsite && (config.websiteUrl?.isNotEmpty ?? false))
        SocialLink(
          name: 'Sitio Web',
          url: config.websiteUrl!,
          icon: Icons.language,
          color: Colors.blueAccent,
        ),
      if (config.showWhatsapp && (config.whatsappNumber?.isNotEmpty ?? false))
        SocialLink(
          name: 'WhatsApp',
          url: 'https://wa.me/${config.whatsappNumber}',
          icon: FontAwesomeIcons.whatsapp,
          color: const Color(0xFF25D366),
        ),
      if (config.showFacebook && (config.facebookUrl?.isNotEmpty ?? false))
        SocialLink(
          name: 'Facebook',
          url: config.facebookUrl!,
          icon: FontAwesomeIcons.facebook,
          color: const Color(0xFF1877F2),
        ),
      if (config.showInstagram && (config.instagramUrl?.isNotEmpty ?? false))
        SocialLink(
          name: 'Instagram',
          url: config.instagramUrl!,
          icon: FontAwesomeIcons.instagram,
          color: const Color(0xFFE4405F),
        ),
      if (config.showTwitter && (config.twitterUrl?.isNotEmpty ?? false))
        SocialLink(
          name: 'Twitter / X',
          url: config.twitterUrl!,
          icon: FontAwesomeIcons.xTwitter,
          color: Colors.white, // FIX: White for dark background
        ),
      if (config.showYoutube && (config.youtubeUrl?.isNotEmpty ?? false))
        SocialLink(
          name: 'YouTube',
          url: config.youtubeUrl!,
          icon: FontAwesomeIcons.youtube,
          color: const Color(0xFFFF0000),
        ),
      if (config.showTiktok && (config.tiktokUrl?.isNotEmpty ?? false))
        SocialLink(
          name: 'TikTok',
          url: config.tiktokUrl!,
          icon: FontAwesomeIcons.tiktok,
          color: Colors.white,
        ),
      if (config.showEmail && (config.contactEmail?.isNotEmpty ?? false))
        SocialLink(
          name: 'Email',
          url: 'mailto:${config.contactEmail}',
          icon: Icons.email_outlined,
          color: Colors.orangeAccent,
        ),
    ];

    final crossAxisCount = _getCrossAxisCount(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Redes Sociales')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Column(
          children: [
            Text(
              'Síguenos',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingSm),
            Text(
              'Visita nuestros canales oficiales',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spacingXl),
            if (socialLinks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No hay enlaces sociales configurados.'),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: AppConstants.spacingMd,
                  mainAxisSpacing: AppConstants.spacingMd,
                  childAspectRatio: 1.2,
                ),
                itemCount: socialLinks.length,
                itemBuilder: (context, index) {
                  // Calcular navegación
                  final row = index ~/ crossAxisCount;
                  final col = index % crossAxisCount;
                  final prevRow = row - 1;
                  final nextRow = row + 1;

                  String? upId;
                  String? downId;
                  String? leftId;
                  String? rightId;

                  // Up
                  if (row > 0) {
                    final upIndex = prevRow * crossAxisCount + col;
                    if (upIndex < socialLinks.length) {
                      upId = 'social_card_$upIndex';
                    }
                  }

                  // Down (Last row -> mini_banner)
                  final downIndex = nextRow * crossAxisCount + col;
                  if (downIndex < socialLinks.length) {
                    downId = 'social_card_$downIndex';
                  } else {
                    downId = 'mini_banner';
                  }

                  // Left (First col -> Nav)
                  if (col > 0) {
                    leftId = 'social_card_${index - 1}';
                  } else {
                    leftId = 'nav_3';
                  }

                  // Right
                  if (col < crossAxisCount - 1 &&
                      index + 1 < socialLinks.length) {
                    rightId = 'social_card_${index + 1}';
                  }

                  return SocialCard(
                    link: socialLinks[index],
                    tvId: 'social_card_$index',
                    tvUpId: upId,
                    tvDownId: downId,
                    tvLeftId: leftId,
                    tvRightId: rightId,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 2;
  }
}
