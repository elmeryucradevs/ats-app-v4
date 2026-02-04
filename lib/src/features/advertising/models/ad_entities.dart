enum AdType {
  video_preroll,
  video_overlay,
  popup_image,
  popup_video,
  banner,
  blog_post,
  blog_scroll_video,
  fullscreen_startup;

  String get label {
    switch (this) {
      case AdType.video_preroll:
        return 'Video Pre-roll';
      case AdType.video_overlay:
        return 'Video Overlay';
      case AdType.popup_image:
        return 'Popup Imagen';
      case AdType.popup_video:
        return 'Popup Video';
      case AdType.banner:
        return 'Banner';
      case AdType.blog_post:
        return 'Post Blog';
      case AdType.blog_scroll_video:
        return 'Video Scroll (Blog)';
      case AdType.fullscreen_startup:
        return 'Fullscreen Startup';
    }
  }
}

enum AdPosition {
  top,
  bottom,
  left_sidebar,
  right_sidebar,
  center,
  fullscreen,
  video_overlay,
  in_feed;
}

enum AdFrequency {
  always_on_startup,
  once_per_session,
  every_x_minutes,
  unlimited;
}

class AdvertisingAd {
  final String id;
  final String campaignId;
  final String title;
  final AdType type;
  final AdPosition position;
  final String mediaUrl;
  final String? redirectUrl;
  final int weight;
  final AdFrequency frequency;
  final int frequencyMinutes;

  AdvertisingAd({
    required this.id,
    required this.campaignId,
    required this.title,
    required this.type,
    required this.position,
    required this.mediaUrl,
    this.redirectUrl,
    this.weight = 50,
    this.frequency = AdFrequency.unlimited,
    this.frequencyMinutes = 0,
  });

  factory AdvertisingAd.fromMap(Map<String, dynamic> map) {
    return AdvertisingAd(
      id: map['id'] ?? '',
      campaignId: map['campaign_id'] ?? '',
      title: map['title'] ?? '',
      type: AdType.values.firstWhere((e) => e.name == map['type'],
          orElse: () => AdType.banner),
      position: AdPosition.values.firstWhere((e) => e.name == map['position'],
          orElse: () => AdPosition.center),
      mediaUrl: map['media_url'] ?? '',
      redirectUrl: map['redirect_url'],
      weight: map['weight'] ?? 50,
      frequency: AdFrequency.values.firstWhere(
          (e) => e.name == map['frequency'],
          orElse: () => AdFrequency.unlimited),
      frequencyMinutes: map['frequency_minutes'] ?? 0,
    );
  }
}
