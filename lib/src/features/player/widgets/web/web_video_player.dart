import 'package:flutter/material.dart';

import 'web_video_player_stub.dart'
    if (dart.library.js_interop) 'web_video_player_web.dart';

class WebVideoPlayer extends StatelessWidget {
  final String streamUrl;
  final bool autoPlay;

  const WebVideoPlayer({
    super.key,
    required this.streamUrl,
    this.autoPlay = true,
  });

  @override
  Widget build(BuildContext context) {
    return WebVideoPlayerImpl(streamUrl: streamUrl, autoPlay: autoPlay);
  }
}
