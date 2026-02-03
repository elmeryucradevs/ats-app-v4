import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:js_interop';
import 'package:flutter/material.dart';

/// Mini version of web video player for the mini player widget
/// Creates a separate iframe instance to display the same stream
class MiniWebVideoPlayer extends StatefulWidget {
  final String streamUrl;

  const MiniWebVideoPlayer({super.key, required this.streamUrl});

  @override
  State<MiniWebVideoPlayer> createState() => _MiniWebVideoPlayerState();
}

class _MiniWebVideoPlayerState extends State<MiniWebVideoPlayer> {
  late String _viewId;
  late String _currentUrl;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.streamUrl;
    _registerIframe();
  }

  @override
  void didUpdateWidget(MiniWebVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If URL changed, create new iframe with new viewId
    if (oldWidget.streamUrl != widget.streamUrl) {
      debugPrint(
          '[MiniWebVideoPlayer] URL changed: ${oldWidget.streamUrl} -> ${widget.streamUrl}');
      _currentUrl = widget.streamUrl;
      setState(() {
        _registerIframe();
      });
    }
  }

  void _registerIframe() {
    // Create unique viewId based on URL and time to force new iframe
    _viewId =
        'mini-hls-video-${widget.streamUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';

    // Register iframe factory
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..srcdoc = _generateMiniPlayerHtml(_currentUrl).toJS;

      return iframe;
    });
  }

  String _generateMiniPlayerHtml(String url) {
    // Detect if URL is HLS (.m3u8) or regular video (.mp4, etc)
    final isHls = url.toLowerCase().contains('.m3u8');

    if (isHls) {
      // Use HLS.js for .m3u8 streams
      return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <!-- HLS.js -->
  <script src="https://cdn.jsdelivr.net/npm/hls.js@1.4.0/dist/hls.min.js"></script>
  <style>
    body { 
      margin: 0; 
      padding: 0; 
      background: #000;
      overflow: hidden;
    }
    #video {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
  </style>
</head>
<body>
  <video id="video" muted autoplay playsinline></video>
  
  <script>
    const video = document.getElementById('video');
    const url = '$url';

    if (Hls.isSupported()) {
      console.log('[Mini IFrame Player] Initializing HLS with URL:', url);
      const hls = new Hls({
        enableWorker: true,
        lowLatencyMode: true,
        backBufferLength: 90,
      });
      
      hls.loadSource(url);
      hls.attachMedia(video);
      
      hls.on(Hls.Events.MANIFEST_PARSED, function() {
        console.log('[Mini IFrame Player] Manifest parsed, attempting autoplay');
        
        // Attempt to play with sound
        video.muted = false;
        video.play().catch(function(error) {
          console.log('[Mini IFrame Player] Autoplay blocked, playing muted');
          video.muted = true;
          video.play();
        });
      });
      
      hls.on(Hls.Events.ERROR, function(event, data) {
        if (data.fatal) {
          console.error('[Mini IFrame Player] Fatal error:', data);
        }
      });
    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      console.log('[Mini IFrame Player] Using native HLS');
      video.src = url;
      video.addEventListener('loadedmetadata', function() {
        video.muted = false;
        video.play().catch(function() {
          video.muted = true;
          video.play();
        });
      });
    }
  </script>
</body>
</html>
''';
    } else {
      // Use native video element for mp4/webm/etc
      return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>
    body { 
      margin: 0; 
      padding: 0; 
      background: #000;
      overflow: hidden;
    }
    #video {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
  </style>
</head>
<body>
  <video id="video" muted autoplay playsinline>
    <source src="$url" type="video/mp4">
    Your browser does not support the video tag.
  </video>
  <script>
    var video = document.getElementById('video');
    
    console.log('[Mini IFrame Player] Initializing MP4 with URL:', "$url");
    
    video.addEventListener('loadeddata', function() {
      console.log('[Mini IFrame Player] Video loaded');
      video.muted = false;
      video.play().catch(function() {
        video.muted = true;
        video.play();
      });
    });
    
    video.addEventListener('error', function(e) {
      console.error('[Mini IFrame Player] Video Error:', e);
    });
  </script>
</body>
</html>
''';
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
