import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ad_entities.dart';

final adServiceProvider = Provider<AdService>((ref) {
  return AdService(Supabase.instance.client);
});

class AdService {
  final SupabaseClient _supabase;

  AdService(this._supabase);

  // Fetch an ad for a specific position and type context
  Future<AdvertisingAd?> getAd({
    required AdPosition position,
    AdType? type,
    String? city,
    String? country,
  }) async {
    try {
      final response =
          await _supabase.functions.invoke('get-advertisement', body: {
        'position': position.name,
        'type': type?.name,
        'city': city,
        'country': country,
      });

      if (response.status == 200 && response.data != null) {
        final data = response.data;
        if (data['ad'] != null) {
          return AdvertisingAd.fromMap(data['ad']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching ad: $e');
      return null;
    }
  }

  Future<void> trackEvent({
    required String adId,
    required String campaignId,
    required String eventType, // 'impression', 'click', 'skip'
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _supabase.functions.invoke('track-ad-event', body: {
        'ad_id': adId,
        'campaign_id': campaignId,
        'event_type': eventType,
        'metadata': metadata ?? {},
        // Browser/App can add more context if needed, but IP is handled by Edge Function better
      });
    } catch (e) {
      print('Error tracking ad event: $e');
    }
  }
}
