import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier para solicitar foco en el menú lateral
/// Incrementa un contador cada vez que se solicita foco
class MenuFocusNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Solicitar foco en el menú - incrementa el contador para notificar listeners
  void requestFocus() {
    state++;
  }
}

/// Provider global para controlar el foco del menú principal
/// Escuchar cambios en este provider para saber cuándo enfocar el menú
final menuFocusControllerProvider =
    NotifierProvider<MenuFocusNotifier, int>(() {
  return MenuFocusNotifier();
});
