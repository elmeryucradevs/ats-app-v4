import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../models/ad_entities.dart';
import '../services/ad_service.dart';

class StartupInterstitial extends ConsumerStatefulWidget {
  final Widget child;
  const StartupInterstitial({super.key, required this.child});

  @override
  ConsumerState<StartupInterstitial> createState() =>
      _StartupInterstitialState();
}

class _StartupInterstitialState extends ConsumerState<StartupInterstitial> {
  AdvertisingAd? _ad;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _checkAndShowAd();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _checkAndShowAd() async {
    // Basic frequency check (e.g. Session based via SharedPreferences)
    final prefs = await SharedPreferences.getInstance();

    // Fetch ad
    final ad = await ref.read(adServiceProvider).getAd(
          position: AdPosition.fullscreen,
          type: AdType.fullscreen_startup,
        );

    if (ad != null) {
      // Initialize video if needed
      if (ad.type == AdType.video_preroll || ad.mediaUrl.endsWith('.mp4')) {
        final controller =
            VideoPlayerController.networkUrl(Uri.parse(ad.mediaUrl));
        try {
          await controller.initialize();
          await controller.setLooping(true);
          await controller.play();
          _videoController = controller;
        } catch (e) {
          debugPrint('Error initializing video ad: $e');
        }
      }

      if (mounted) {
        setState(() {
          _ad = ad;
        });
        // Track Impression
        ref.read(adServiceProvider).trackEvent(
            adId: ad.id, campaignId: ad.campaignId, eventType: 'impression');
      }
    }
  }

  void _closeAd() {
    _videoController?.pause();
    setState(() => _ad = null);
  }

  Future<void> _onTapAd() async {
    _videoController?.pause();
    if (_ad?.redirectUrl != null) {
      final url = Uri.parse(_ad!.redirectUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        ref.read(adServiceProvider).trackEvent(
            adId: _ad!.id, campaignId: _ad!.campaignId, eventType: 'click');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ad == null) return widget.child;

    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: Material(
            color: Colors.black.withOpacity(0.9), // Dark background
            child: Stack(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: _onTapAd,
                    child: _buildAdContent(),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: _closeAd,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdContent() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: VideoPlayer(_videoController!),
      );
    }

    if (_ad!.type == AdType.video_preroll || _ad!.mediaUrl.endsWith('.mp4')) {
      // Still loading video or failed
      return const CircularProgressIndicator(color: Colors.white);
    }

    // Image
    return CachedNetworkImage(
      imageUrl: _ad!.mediaUrl,
      fit: BoxFit.contain,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }
}
