/// In-App Message Dialog Widget
/// Displays custom in-app messages from Supabase with multiple layout styles
library;

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/inapp_message_model.dart';
import '../../../core/services/inapp_message_service.dart';
import '../../../core/router/app_router.dart'; // For rootNavigatorKey

class InAppMessageDialog extends StatelessWidget {
  final InAppMessage message;
  final VoidCallback onDismiss;

  const InAppMessageDialog({
    super.key,
    required this.message,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Render based on layout type
    switch (message.layout) {
      case 'modal':
        return _buildModalLayout(context);
      case 'banner':
        return _buildBannerLayout(context);
      case 'image':
        return _buildImageOnlyLayout(context);
      case 'card':
      default:
        return _buildCardLayout(context);
    }
  }

  /// CARD Layout - Centered card with all elements
  Widget _buildCardLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Icon(Icons.close,
                    color: isDark ? Colors.white54 : Colors.black45),
                onPressed: onDismiss,
              ),
            ),

            // Image
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: message.imageUrl!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      height: 160,
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    message.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message.body,
                    style: TextStyle(
                      fontSize: 15,
                      color: isDark ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildActionButton(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// MODAL Layout - Fullscreen with gradient overlay
  Widget _buildModalLayout(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: SafeArea(
        child: Stack(
          children: [
            // Background image
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: Colors.black),
                ),
              ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: onDismiss,
              ),
            ),

            // Content at bottom
            Positioned(
              left: 24,
              right: 24,
              bottom: 48,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    message.body,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionButton(context, large: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// BANNER Layout - Top or bottom sliding banner
  Widget _buildBannerLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Tap to dismiss background
          GestureDetector(
            onTap: onDismiss,
            child: Container(color: Colors.black26),
          ),

          // Banner at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              elevation: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Stack(
                  children: [
                    // Content Row
                    Padding(
                      padding: EdgeInsets.only(
                        top: 16,
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.of(context).padding.bottom + 16,
                      ),
                      child: Row(
                        children: [
                          // Image thumbnail
                          if (message.imageUrl != null &&
                              message.imageUrl!.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: message.imageUrl!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                          if (message.imageUrl != null &&
                              message.imageUrl!.isNotEmpty)
                            const SizedBox(width: 12),

                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  message.title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message.body,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white70
                                        : Colors.black54,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Action button
                          ElevatedButton(
                            onPressed: () => _handleAction(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                            ),
                            child: Text(message.buttonText),
                          ),
                        ],
                      ),
                    ),

                    // Close button inside banner (top-right corner)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onDismiss,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black12,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.close,
                            color: isDark ? Colors.white70 : Colors.black54,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// IMAGE ONLY Layout - Just the image with close and action buttons
  Widget _buildImageOnlyLayout(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Image
          if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
            GestureDetector(
              onTap: () => _handleAction(context),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: CachedNetworkImage(
                  imageUrl: message.imageUrl!,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white54, size: 48),
                    ),
                  ),
                ),
              ),
            )
          else
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    message.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message.body,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {bool large = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _handleAction(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: large ? 16 : 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          message.buttonText,
          style: TextStyle(
            fontSize: large ? 18 : 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context) async {
    // Record click
    InAppMessageService().recordClick(message.id);

    // Handle action URL if present
    if (message.actionUrl != null && message.actionUrl!.isNotEmpty) {
      final uri = Uri.tryParse(message.actionUrl!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }

    onDismiss();
  }

  /// Show the in-app message dialog using global navigator key
  static void show(BuildContext context, InAppMessage message) {
    // Get context from global navigator key (avoids context-above-navigator issue)
    final navigatorContext = rootNavigatorKey.currentContext;
    if (navigatorContext == null) {
      debugPrint('InAppMessageDialog: No navigator context available');
      return;
    }

    // Mark as shown immediately
    InAppMessageService().markAsShown(message.id);
    InAppMessageService().recordView(message.id);

    // Use different show method based on layout
    if (message.layout == 'modal') {
      // Modal uses full screen
      Navigator.of(navigatorContext).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => InAppMessageDialog(
            message: message,
            onDismiss: () => Navigator.of(navigatorContext).pop(),
          ),
        ),
      );
    } else if (message.layout == 'banner') {
      // Banner uses overlay
      Navigator.of(navigatorContext).push(
        PageRouteBuilder(
          opaque: false,
          pageBuilder: (_, __, ___) => InAppMessageDialog(
            message: message,
            onDismiss: () => Navigator.of(navigatorContext).pop(),
          ),
        ),
      );
    } else {
      // Card and Image use dialog
      showDialog(
        context: navigatorContext,
        barrierDismissible: true,
        builder: (ctx) => InAppMessageDialog(
          message: message,
          onDismiss: () => Navigator.of(ctx).pop(),
        ),
      );
    }
  }
}
