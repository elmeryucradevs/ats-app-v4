import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/services/supabase_service.dart';
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
  List<AdvertisingAd> _ads = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  PageController? _pageController;
  Timer? _autoPlayTimer;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    final ads = await ref.read(adServiceProvider).getAds(
          position: widget.position,
          type: AdType.banner,
          city: widget.city,
          channelId: SupabaseService.channelId,
        );

    if (mounted) {
      _pageController = PageController(initialPage: 0);
      setState(() {
        _ads = ads;
        _isLoading = false;
      });

      if (_ads.isNotEmpty) {
        // Track impression for the first active ad
        ref.read(adServiceProvider).trackEvent(
              adId: _ads[0].id,
              campaignId: _ads[0].campaignId,
              eventType: 'impression',
              metadata: widget.metadata,
            );
        _startAutoPlay();
      }
    }
  }

  void _startAutoPlay() {
    _stopAutoPlay();
    if (_ads.length <= 1) return;

    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isHovered) return; // Pause rotation on hover
      if (_pageController != null && _pageController!.hasClients) {
        final nextPage = (_currentIndex + 1) % _ads.length;
        _pageController!.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Track impression when slide changes
    ref.read(adServiceProvider).trackEvent(
          adId: _ads[index].id,
          campaignId: _ads[index].campaignId,
          eventType: 'impression',
          metadata: widget.metadata,
        );
  }

  void _prevAd() {
    if (_ads.isEmpty) return;
    final prevPage = (_currentIndex - 1 + _ads.length) % _ads.length;
    _pageController?.animateToPage(
      prevPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _nextAd() {
    if (_ads.isEmpty) return;
    final nextPage = (_currentIndex + 1) % _ads.length;
    _pageController?.animateToPage(
      nextPage,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onTap(AdvertisingAd ad) async {
    if (ad.redirectUrl != null) {
      final url = Uri.parse(ad.redirectUrl!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        ref.read(adServiceProvider).trackEvent(
              adId: ad.id,
              campaignId: ad.campaignId,
              eventType: 'click',
              metadata: widget.metadata,
            );
      }
    }
  }

  Widget _buildArrowButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return AnimatedOpacity(
      opacity: _isHovered ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.4),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            hoverColor: Colors.white.withOpacity(0.15),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (_ads.isEmpty) return const SizedBox.shrink();

    // Determine dimensions based on position or ad specifications
    double bannerHeight;
    double? bannerWidth;

    switch (widget.position) {
      case AdPosition.left_sidebar:
      case AdPosition.right_sidebar:
        bannerHeight = 600.0;
        bannerWidth = 160.0; // Standard skyscraper width
        break;
      case AdPosition.in_feed:
        bannerHeight = 250.0;
        bannerWidth = 300.0; // Standard in-feed rectangle width
        break;
      case AdPosition.top:
      case AdPosition.bottom:
      case AdPosition.center:
      default:
        bannerHeight = 90.0;
        bannerWidth = null; // Leaderboards take full screen horizontal width
        break;
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    double resolvedHeight = bannerHeight;
    double? resolvedWidth = bannerWidth;

    // Responsive scaling for horizontal and skyscraper banners on mobile devices
    if (widget.position == AdPosition.top ||
        widget.position == AdPosition.bottom ||
        widget.position == AdPosition.center) {
      if (screenWidth < 768) {
        resolvedHeight = 50.0; // Standard mobile banner height (e.g., 320x50)
      }
    } else if (widget.position == AdPosition.left_sidebar ||
        widget.position == AdPosition.right_sidebar) {
      if (screenWidth < 768) {
        resolvedHeight = 250.0; // Shrink skyscraper sidebar ads if screen is tight
        resolvedWidth = screenWidth; // Allow full width when stacked vertically on mobile
      }
    }

    if (_ads.length == 1) {
      final ad = _ads[0];
      return GestureDetector(
        onTap: () => _onTap(ad),
        child: Container(
          height: resolvedHeight,
          width: resolvedWidth,
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: ad.mediaUrl,
              placeholder: (_, __) => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (_, __, ___) => const SizedBox.shrink(),
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        height: resolvedHeight,
        width: resolvedWidth,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.antiAlias,
          children: [
            // 1. Sliding Advertisements PageView
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _ads.length,
                itemBuilder: (context, index) {
                  final ad = _ads[index];
                  return GestureDetector(
                    onTap: () => _onTap(ad),
                    child: CachedNetworkImage(
                      imageUrl: ad.mediaUrl,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      fit: BoxFit.contain,
                    ),
                  );
                },
              ),
            ),

            // 2. Navigation Circular Glassmorphic Buttons (Fades in/out on hover)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildArrowButton(
                  icon: Icons.chevron_left_rounded,
                  onPressed: _prevAd,
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildArrowButton(
                  icon: Icons.chevron_right_rounded,
                  onPressed: _nextAd,
                ),
              ),
            ),

            // 3. Carousel Dot Indicators (Clickable to jump directly to an advertisement)
            Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_ads.length, (index) {
                  final isSelected = _currentIndex == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController?.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: isSelected ? 18 : 6,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.tealAccent.shade400
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.tealAccent.shade400
                                      .withOpacity(0.6),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
