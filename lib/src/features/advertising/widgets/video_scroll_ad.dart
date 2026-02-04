import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../models/ad_entities.dart';
import '../services/ad_service.dart';

class VideoScrollAd extends ConsumerStatefulWidget {
  final String? city;

  const VideoScrollAd({super.key, this.city});

  @override
  ConsumerState<VideoScrollAd> createState() => _VideoScrollAdState();
}

class _VideoScrollAdState extends ConsumerState<VideoScrollAd> {
  AdvertisingAd? _ad;
  VideoPlayerController? _controller;
  bool _isLoading = true;
  bool _hasImpressionTracked = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final ad = await ref.read(adServiceProvider).getAd(
          position: AdPosition.in_feed, // or blog_post
          type: AdType.blog_scroll_video,
          city: widget.city,
        );

    if (mounted) {
      if (ad != null && ad.mediaUrl.isNotEmpty) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(ad.mediaUrl))
          ..initialize().then((_) {
            _controller!.setLooping(true);
            _controller!.setVolume(0); // Muted by default
            setState(() {});
          });
      }
      setState(() {
        _ad = ad;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (info.visibleFraction > 0.5) {
      if (!_controller!.value.isPlaying) {
        _controller!.play();
      }
      if (!_hasImpressionTracked && _ad != null) {
        _hasImpressionTracked = true;
        ref.read(adServiceProvider).trackEvent(
            adId: _ad!.id,
            campaignId: _ad!.campaignId,
            eventType: 'impression');
      }
    } else {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator()));
    if (_ad == null || _controller == null || !_controller!.value.isInitialized)
      return const SizedBox.shrink();

    return VisibilityDetector(
      key: Key('video-ad-${_ad!.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        height: 250,
        margin: const EdgeInsets.symmetric(vertical: 16),
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: _controller!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller!),
              VideoProgressIndicator(_controller!, allowScrubbing: false),
            ],
          ),
        ),
      ),
    );
  }
}
