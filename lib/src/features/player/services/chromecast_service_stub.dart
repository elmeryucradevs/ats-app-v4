import 'dart:developer' as developer;
import 'package:flutter/material.dart';

/// Stub for Chromecast service on non-web platforms
class ChromecastService {
  static final ChromecastService _instance = ChromecastService._internal();
  factory ChromecastService() => _instance;
  ChromecastService._internal();

  final ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);

  bool get isAvailable => false;

  Future<void> initialize() async {
    developer.log('Not available on this platform', name: 'ChromecastService');
  }

  void openDeviceSelector(BuildContext parentContext) {
    developer.log('Not available on this platform', name: 'ChromecastService');
  }

  Widget buildCastButton({required BuildContext context}) {
    // Return empty widget instead of throwing or showing nothing
    return const SizedBox.shrink();
  }

  Future<void> loadMedia(String mediaUrl, {String title = 'ATESUR TV'}) async {
    developer.log('Not available on this platform', name: 'ChromecastService');
  }
}
