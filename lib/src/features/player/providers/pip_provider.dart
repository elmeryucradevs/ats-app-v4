import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_pip_mode/simple_pip.dart';

/// Provider to track if the app is currently in PiP mode
final pipProvider = NotifierProvider<PipNotifier, bool>(PipNotifier.new);

class PipNotifier extends Notifier<bool> {
  late final SimplePip _pip;

  @override
  bool build() {
    _pip = SimplePip(
      onPipEntered: () {
        state = true;
      },
      onPipExited: () {
        state = false;
      },
    );
    return false;
  }

  /// Request to enter PiP mode
  Future<void> enterPipMode() async {
    await _pip.enterPipMode();
  }
}
