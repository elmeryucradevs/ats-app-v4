/// Wrapper widget that listens for in-app messages and shows dialogs
library;

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/inapp_message_service.dart';
import 'inapp_message_dialog.dart';

class InAppMessageListener extends StatefulWidget {
  final Widget child;

  const InAppMessageListener({
    super.key,
    required this.child,
  });

  @override
  State<InAppMessageListener> createState() => _InAppMessageListenerState();
}

class _InAppMessageListenerState extends State<InAppMessageListener> {
  StreamSubscription? _subscription;
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    _listenForMessages();
  }

  void _listenForMessages() {
    _subscription = InAppMessageService().messageStream.listen((message) {
      if (message != null && !_isShowingDialog && mounted) {
        _isShowingDialog = true;

        // Use a post-frame callback to ensure context is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            InAppMessageDialog.show(context, message);
            _isShowingDialog = false;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
