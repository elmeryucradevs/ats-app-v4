import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/ad_entities.dart';
import '../services/ad_service.dart';

class SmartBanner extends ConsumerStatefulWidget {
  final AdPosition position;
  final String? city;
  final Map<String, dynamic>? metadata;

  const SmartBanner({
    super.key,
    required this.position,
    this.city,
    this.metadata,
  });

  @override
  ConsumerState<SmartBanner> createState() => _SmartBannerState();
}

class _SmartBannerState extends ConsumerState<SmartBanner> {
  AdvertisingAd? _ad;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final ad = await ref.read(adServiceProvider).getAd(
          position: widget.position,
          type: AdType.banner,
          city: widget.city,
        );

    if (mounted) {
      if (ad != null) {
        ref.read(adServiceProvider).trackEvent(
              adId: ad.id,
              campaignId: ad.campaignId,
              eventType: 'impression',
              metadata: widget.metadata,
            );
      }
      setState(() {
        _ad = ad;
        _isLoading = false;
      });
    }
  }

  Future<void> _onTap() async {
    if (_ad?.redirectUrl != null) {
      final url = Uri.parse(_ad!.redirectUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        ref.read(adServiceProvider).trackEvent(
              adId: _ad!.id,
              campaignId: _ad!.campaignId,
              eventType: 'click',
              metadata: widget.metadata,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink(); // Or placeholder
    if (_ad == null) return const SizedBox.shrink();

    // Determine dimensions based on position or ad specs?
    // For now we trust the image/container.
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: CachedNetworkImage(
          imageUrl: _ad!.mediaUrl,
          placeholder: (_, __) => const SizedBox(
              height: 50, child: Center(child: CircularProgressIndicator())),
          errorWidget: (_, __, ___) => const SizedBox.shrink(),
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
