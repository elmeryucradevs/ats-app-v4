import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/social_link.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';

/// Card para un enlace de red social
class SocialCard extends StatelessWidget {
  const SocialCard({
    required this.link,
    super.key,
    this.tvId,
    this.tvUpId,
    this.tvDownId,
    this.tvLeftId,
    this.tvRightId,
  });

  final SocialLink link;

  // TV Navigation IDs
  final String? tvId;
  final String? tvUpId;
  final String? tvDownId;
  final String? tvLeftId;
  final String? tvRightId;

  @override
  Widget build(BuildContext context) {
    if (!link.isAvailable) {
      return const SizedBox.shrink();
    }

    final cardContent = Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            link.icon,
            size: AppConstants.iconSizeXl * 1.2,
            color: link.color,
          ),
          const SizedBox(height: AppConstants.spacingMd),
          Text(
            link.name,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );

    // Si tiene TV ID, usar TVCard para navegación
    if (tvId != null) {
      return TVCard(
        id: tvId!,
        upId: tvUpId,
        downId: tvDownId,
        leftId: tvLeftId,
        rightId: tvRightId,
        margin: EdgeInsets.zero,
        onTap: () => _launchUrl(link.url),
        child: cardContent,
      );
    }

    // Fallback a Card normal si no hay TV ID
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _launchUrl(link.url),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        child: cardContent,
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
