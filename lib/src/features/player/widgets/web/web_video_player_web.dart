import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;
import 'dart:js_interop';
import 'package:flutter/material.dart';

class WebVideoPlayerImpl extends StatefulWidget {
  final String streamUrl;
  final bool autoPlay;

  const WebVideoPlayerImpl({
    super.key,
    required this.streamUrl,
    this.autoPlay = true,
  });

  @override
  State<WebVideoPlayerImpl> createState() => _WebVideoPlayerImplState();
}

class _WebVideoPlayerImplState extends State<WebVideoPlayerImpl> {
  late String _viewId;
  late String _currentUrl;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.streamUrl;
    _registerIframe();
  }

  @override
  void didUpdateWidget(WebVideoPlayerImpl oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If URL changed, create new iframe with new viewId
    if (oldWidget.streamUrl != widget.streamUrl) {
      debugPrint(
          '[WebVideoPlayer] URL changed: ${oldWidget.streamUrl} -> ${widget.streamUrl}');
      _currentUrl = widget.streamUrl;
      setState(() {
        _registerIframe();
      });
    }
  }

  void _registerIframe() {
    // Create unique viewId based on URL and time to force new iframe
    _viewId =
        'hls-video-${widget.streamUrl.hashCode}-${DateTime.now().millisecondsSinceEpoch}';

    // Register iframe factory
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..srcdoc = _generatePlayerHtml(_currentUrl, widget.autoPlay).toJS;

      return iframe;
    });
  }

  String _generatePlayerHtml(String url, bool autoPlay) {
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
      object-fit: contain;
    }
  </style>
</head>
<body>
  <video id="video" controls muted autoplay playsinline></video>
  <script>
    var video = document.getElementById('video');
    var url = "$url";
    var autoplayRequested = ${autoPlay ? 'true' : 'false'};
    
    console.log('[IFrame Player] Initializing HLS with URL:', url);
    
    // Autoplay with muted to bypass browser restrictions
    function attemptAutoplay() {
      if (autoplayRequested) {
        video.play().then(() => {
          console.log('[IFrame Player] Autoplay successful (muted)');
          // Unmute after 1 second if user hasn't interacted
          setTimeout(() => {
            video.muted = false;
            console.log('[IFrame Player] Unmuted');
          }, 1000);
        }).catch(e => {
          console.log('[IFrame Player] Autoplay blocked:', e);
        });
      }
    }
    
    if (window.Hls && Hls.isSupported()) {
      console.log('[IFrame Player] Using Hls.js');
      var hls = new Hls();
      hls.loadSource(url);
      hls.attachMedia(video);
      hls.on(Hls.Events.MANIFEST_PARSED, function() {
        console.log('[IFrame Player] Manifest parsed');
        attemptAutoplay();
      });
      hls.on(Hls.Events.ERROR, function(event, data) {
        console.error('[IFrame Player] HLS Error:', data);
      });
    } else if (video.canPlayType('application/vnd.apple.mpegurl')) {
      console.log('[IFrame Player] Using native HLS');
      video.src = url;
      attemptAutoplay();
    } else {
      console.error('[IFrame Player] HLS not supported');
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
      object-fit: contain;
    }
  </style>
</head>
<body>
  <video id="video" controls muted autoplay playsinline>
    <source src="$url" type="video/mp4">
    Your browser does not support the video tag.
  </video>
  <script>
    var video = document.getElementById('video');
    var autoplayRequested = ${autoPlay ? 'true' : 'false'};
    
    console.log('[IFrame Player] Initializing MP4 with URL:', "$url");
    
    // Autoplay with muted to bypass browser restrictions
    function attemptAutoplay() {
      if (autoplayRequested) {
        video.play().then(() => {
          console.log('[IFrame Player] Autoplay successful (muted)');
          // Unmute after 1 second
          setTimeout(() => {
            video.muted = false;
            console.log('[IFrame Player] Unmuted');
          }, 1000);
        }).catch(e => {
          console.log('[IFrame Player] Autoplay blocked:', e);
        });
      }
    }
    
    video.addEventListener('loadeddata', function() {
      console.log('[IFrame Player] Video loaded');
      attemptAutoplay();
    });
    
    video.addEventListener('error', function(e) {
      console.error('[IFrame Player] Video Error:', e);
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
