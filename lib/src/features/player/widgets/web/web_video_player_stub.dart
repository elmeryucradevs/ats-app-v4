import 'package:flutter/material.dart';

class WebVideoPlayerImpl extends StatelessWidget {
  final String streamUrl;
  final bool autoPlay;

  const WebVideoPlayerImpl({
    super.key,
    required this.streamUrl,
    this.autoPlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Video player not available on mobile'));
  }
}
