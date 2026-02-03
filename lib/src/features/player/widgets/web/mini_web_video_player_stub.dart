import 'package:flutter/material.dart';

/// Stub for non-web platforms
class MiniWebVideoPlayer extends StatelessWidget {
  final String streamUrl;

  const MiniWebVideoPlayer({super.key, required this.streamUrl});

  @override
  Widget build(BuildContext context) {
    // On non-web platforms, return empty widget
    // The mini player will use VideoPlayer instead
    return const SizedBox.shrink();
  }
}
