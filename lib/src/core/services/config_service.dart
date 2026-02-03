import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';
import '../config/env_config.dart';
import 'supabase_service.dart';

/// Configuration State Model
class AppConfigState {
  final String streamUrl;
  final String wordpressUrl;
  final String logoUrl;

  // Social & Contact Data
  final String? facebookUrl;
  final String? instagramUrl;
  final String? twitterUrl;
  final String? youtubeUrl;
  final String? tiktokUrl;
  final String? whatsappNumber;
  final String? contactEmail;
  final String? websiteUrl;

  // Visibility Flags
  final bool showFacebook;
  final bool showInstagram;
  final bool showTwitter;
  final bool showYoutube;
  final bool showTiktok;
  final bool showWhatsapp;
  final bool showEmail;
  final bool showWebsite;

  final bool updateRequired;
  final String? latestVersion;

  const AppConfigState({
    required this.streamUrl,
    required this.wordpressUrl,
    required this.logoUrl,
    this.facebookUrl,
    this.instagramUrl,
    this.twitterUrl,
    this.youtubeUrl,
    this.tiktokUrl,
    this.whatsappNumber,
    this.contactEmail,
    this.websiteUrl,
    this.showFacebook = true,
    this.showInstagram = true,
    this.showTwitter = true,
    this.showYoutube = true,
    this.showTiktok = true,
    this.showWhatsapp = true,
    this.showEmail = true,
    this.showWebsite = true,
    this.updateRequired = false,
    this.latestVersion,
  });

  AppConfigState copyWith({
    String? streamUrl,
    String? wordpressUrl,
    String? logoUrl,
    String? facebookUrl,
    String? instagramUrl,
    String? twitterUrl,
    String? youtubeUrl,
    String? tiktokUrl,
    String? whatsappNumber,
    String? contactEmail,
    String? websiteUrl,
    bool? showFacebook,
    bool? showInstagram,
    bool? showTwitter,
    bool? showYoutube,
    bool? showTiktok,
    bool? showWhatsapp,
    bool? showEmail,
    bool? showWebsite,
    bool? updateRequired,
    String? latestVersion,
  }) {
    return AppConfigState(
      streamUrl: streamUrl ?? this.streamUrl,
      wordpressUrl: wordpressUrl ?? this.wordpressUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      facebookUrl: facebookUrl ?? this.facebookUrl,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      contactEmail: contactEmail ?? this.contactEmail,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      showFacebook: showFacebook ?? this.showFacebook,
      showInstagram: showInstagram ?? this.showInstagram,
      showTwitter: showTwitter ?? this.showTwitter,
      showYoutube: showYoutube ?? this.showYoutube,
      showTiktok: showTiktok ?? this.showTiktok,
      showWhatsapp: showWhatsapp ?? this.showWhatsapp,
      showEmail: showEmail ?? this.showEmail,
      showWebsite: showWebsite ?? this.showWebsite,
      updateRequired: updateRequired ?? this.updateRequired,
      latestVersion: latestVersion ?? this.latestVersion,
    );
  }
}

/// Service configured as a NotifierProvider
final configServiceProvider =
    NotifierProvider<ConfigServiceNotifier, AppConfigState>(
  ConfigServiceNotifier.new,
);

class ConfigServiceNotifier extends Notifier<AppConfigState> {
  // Supabase Table Name
  static const String _tableConfig = 'app_config';

  // State keys
  static const String _keyStreamUrl = 'stream_url';
  static const String _keyWordpressUrl = 'wordpress_url';
  static const String _keyLogoUrl = 'logo_url';

  // Social Keys
  static const String _keyFacebookUrl = 'facebook_url';
  static const String _keyInstagramUrl = 'instagram_url';
  static const String _keyTwitterUrl = 'twitter_url';
  static const String _keyYoutubeUrl = 'youtube_url';
  static const String _keyTiktokUrl = 'tiktok_url';
  static const String _keyWhatsappNumber = 'whatsapp_number';
  static const String _keyContactEmail = 'contact_email';
  static const String _keyWebsiteUrl = 'website_url';

  // Visibility Keys
  static const String _keyShowFacebook = 'show_facebook';
  static const String _keyShowInstagram = 'show_instagram';
  static const String _keyShowTwitter = 'show_twitter';
  static const String _keyShowYoutube = 'show_youtube';
  static const String _keyShowTiktok = 'show_tiktok';
  static const String _keyShowWhatsapp = 'show_whatsapp';
  static const String _keyShowEmail = 'show_email';
  static const String _keyShowWebsite = 'show_website';

  // Remote Config Keys
  static const String _rcMinVersion = 'min_supported_version';
  static const String _rcLatestVersion = 'latest_version';

  @override
  AppConfigState build() {
    // Initial state with defaults from EnvConfig
    return AppConfigState(
      streamUrl: EnvConfig.streamUrl,
      wordpressUrl: EnvConfig.wordpressApiUrl,
      logoUrl: '',
    );
  }

  /// Initialize: Remote Config first (technical), then Supabase (content)
  Future<void> initialize() async {
    await _initRemoteConfig();
    await _initSupabaseConfig();
  }

  // ===================================
  // FIREBASE REMOTE CONFIG (Technical)
  // ===================================
  Future<void> _initRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;

      // Defaul values
      await remoteConfig.setDefaults({
        _rcMinVersion: '1.0.0',
        _rcLatestVersion: '1.0.0',
      });

      // Fetch
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(
          hours: 1,
        ), // Reduce for dev
      ));

      await remoteConfig.fetchAndActivate();

      // Check Version
      await _checkVersion(remoteConfig);
    } catch (e) {
      AppLogger.error('[ConfigService] Remote Config Init Error', e);
    }
  }

  Future<void> _checkVersion(FirebaseRemoteConfig rc) async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      final minVersion = rc.getString(_rcMinVersion);
      final latestVersion = rc.getString(_rcLatestVersion);

      AppLogger.info(
        '[ConfigService] Version Check: Current=$currentVersion, Min=$minVersion',
      );

      final isUpdateRequired = _isVersionLower(currentVersion, minVersion);

      if (isUpdateRequired) {
        state = state.copyWith(
          updateRequired: true,
          latestVersion: latestVersion,
        );
      }
    } catch (e) {
      AppLogger.error('[ConfigService] Version Check Error', e);
    }
  }

  // Helper: Returns true if v1 < v2
  bool _isVersionLower(String v1, String v2) {
    try {
      final p1 = v1.split('.').map(int.parse).toList();
      final p2 = v2.split('.').map(int.parse).toList();

      for (int i = 0; i < 3; i++) {
        final n1 = i < p1.length ? p1[i] : 0;
        final n2 = i < p2.length ? p2[i] : 0;
        if (n1 < n2) return true;
        if (n1 > n2) return false;
      }
      return false; // Equal
    } catch (_) {
      return false; // Fallback
    }
  }

  // ===================================
  // SUPABASE (Content)
  // ===================================
  Future<void> _initSupabaseConfig() async {
    try {
      final supabase = SupabaseService.client;

      AppLogger.info(
          '[ConfigService] Fetching config from Supabase table: $_tableConfig');

      // 1. Initial Fetch
      final response = await supabase.from(_tableConfig).select().maybeSingle();

      if (response != null) {
        _updateStateFromSupabase(response);
      } else {
        AppLogger.warning(
          '[ConfigService] No config found in Supabase table $_tableConfig. '
          'Make sure the table exists and has at least one row.',
        );
      }

      // 2. Realtime Subscription
      supabase
          .channel('public:$_tableConfig')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: _tableConfig,
            callback: (payload) {
              AppLogger.info('[ConfigService] Realtime config update detected');
              _updateStateFromSupabase(payload.newRecord);
            },
          )
          .subscribe();
    } catch (e, s) {
      AppLogger.error('[ConfigService] Supabase Init Error: $e', e, s);
    }
  }

  void _updateStateFromSupabase(Map<String, dynamic> data) {
    final streamUrl = data[_keyStreamUrl] as String?;
    final wordpressUrl = data[_keyWordpressUrl] as String?;
    final logoUrl = data[_keyLogoUrl] as String?;

    // Social
    final facebookUrl = data[_keyFacebookUrl] as String?;
    final instagramUrl = data[_keyInstagramUrl] as String?;
    final twitterUrl = data[_keyTwitterUrl] as String?;
    final youtubeUrl = data[_keyYoutubeUrl] as String?;
    final tiktokUrl = data[_keyTiktokUrl] as String?;
    final whatsappNumber = data[_keyWhatsappNumber] as String?;
    final contactEmail = data[_keyContactEmail] as String?;
    final websiteUrl = data[_keyWebsiteUrl] as String?;

    // Visibility
    // Note: Use 'as bool? ?? true' to default to visible if missing
    final showFacebook = data[_keyShowFacebook] as bool? ?? true;
    final showInstagram = data[_keyShowInstagram] as bool? ?? true;
    final showTwitter = data[_keyShowTwitter] as bool? ?? true;
    final showYoutube = data[_keyShowYoutube] as bool? ?? true;
    final showTiktok = data[_keyShowTiktok] as bool? ?? true;
    final showWhatsapp = data[_keyShowWhatsapp] as bool? ?? true;
    final showEmail = data[_keyShowEmail] as bool? ?? true;
    final showWebsite = data[_keyShowWebsite] as bool? ?? true;

    state = state.copyWith(
      streamUrl: (streamUrl != null && streamUrl.isNotEmpty) ? streamUrl : null,
      wordpressUrl: (wordpressUrl != null && wordpressUrl.isNotEmpty)
          ? wordpressUrl
          : null,
      logoUrl: logoUrl,
      facebookUrl: facebookUrl,
      instagramUrl: instagramUrl,
      twitterUrl: twitterUrl,
      youtubeUrl: youtubeUrl,
      tiktokUrl: tiktokUrl,
      whatsappNumber: whatsappNumber,
      contactEmail: contactEmail,
      websiteUrl: websiteUrl,
      showFacebook: showFacebook,
      showInstagram: showInstagram,
      showTwitter: showTwitter,
      showYoutube: showYoutube,
      showTiktok: showTiktok,
      showWhatsapp: showWhatsapp,
      showEmail: showEmail,
      showWebsite: showWebsite,
    );
  }
}
