import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier para controlar el modo pantalla completa de TV
class TvFullscreenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }

  void set(bool value) {
    state = value;
  }
}

/// Provider para controlar el modo pantalla completa de TV
/// Cuando está activo, MainShell ocultará el NavigationRail
final tvFullscreenProvider = NotifierProvider<TvFullscreenNotifier, bool>(() {
  return TvFullscreenNotifier();
});
