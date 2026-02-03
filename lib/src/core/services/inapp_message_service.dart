/// Service for handling in-app messages from Supabase
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/inapp_message_model.dart';

class InAppMessageService {
  static final InAppMessageService _instance = InAppMessageService._internal();
  factory InAppMessageService() => _instance;
  InAppMessageService._internal();

  final _supabase = Supabase.instance.client;
  final _messageController = StreamController<InAppMessage?>.broadcast();
  StreamSubscription? _subscription;
  String? _lastShownMessageId;
  static const _lastShownKey = 'last_shown_inapp_message_id';

  Stream<InAppMessage?> get messageStream => _messageController.stream;

  /// Initialize and start listening for active messages
  Future<void> initialize() async {
    // Load last shown message ID
    final prefs = await SharedPreferences.getInstance();
    _lastShownMessageId = prefs.getString(_lastShownKey);

    // Check for active messages immediately
    await _checkForActiveMessages();

    // Subscribe to realtime changes
    _subscription = _supabase
        .from('inapp_messages')
        .stream(primaryKey: ['id']).listen((data) {
      _handleRealtimeUpdate(data);
    });

    debugPrint('InAppMessageService: Initialized');
  }

  Future<void> _checkForActiveMessages() async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('inapp_messages')
          .select()
          .eq('is_active', true)
          .lte('start_date', now)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final message = InAppMessage.fromJson(response.first);

        // Check if end_date has passed
        if (message.endDate != null &&
            message.endDate!.isBefore(DateTime.now())) {
          return;
        }

        // Only show if not already shown
        if (message.id != _lastShownMessageId) {
          _messageController.add(message);
        }
      }
    } catch (e) {
      debugPrint('InAppMessageService: Error checking messages: $e');
    }
  }

  void _handleRealtimeUpdate(List<Map<String, dynamic>> data) {
    // Find active messages
    final activeMessages = data
        .where((m) => m['is_active'] == true)
        .map((m) => InAppMessage.fromJson(m))
        .toList();

    if (activeMessages.isNotEmpty) {
      // Get the most recent active message
      final message = activeMessages.first;

      // Check if not already shown
      if (message.id != _lastShownMessageId) {
        _messageController.add(message);
      }
    }
  }

  /// Mark a message as shown (won't show again)
  Future<void> markAsShown(String messageId) async {
    _lastShownMessageId = messageId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastShownKey, messageId);
    debugPrint('InAppMessageService: Marked message $messageId as shown');
  }

  /// Record a view for analytics
  Future<void> recordView(String messageId) async {
    try {
      // Increment views_count
      await _supabase
          .rpc('increment_inapp_views', params: {'message_id': messageId});
    } catch (e) {
      debugPrint('InAppMessageService: Error recording view: $e');
    }
  }

  /// Record a click for analytics
  Future<void> recordClick(String messageId) async {
    try {
      // Increment clicks_count
      await _supabase
          .rpc('increment_inapp_clicks', params: {'message_id': messageId});
    } catch (e) {
      debugPrint('InAppMessageService: Error recording click: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _messageController.close();
  }
}
