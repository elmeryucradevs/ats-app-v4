import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Provider para el modo de tema actual
///
/// Permite cambiar entre tema claro y oscuro,y persiste la preferencia del usuario.
/// Por defecto, sigue el tema del sistema.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() {
  return ThemeModeNotifier();
});

/// Notifier para gestionar el modo de tema
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Cargar preferencia guardada al inicializar
    _loadThemeMode();
    return ThemeMode.system;
  }

  /// Carga el modo de tema guardado en SharedPreferences
  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTheme = prefs.getString(StorageKeys.themeMode);

      AppLogger.debug('[ThemeMode] Tema guardado: $savedTheme');

      if (savedTheme != null) {
        switch (savedTheme) {
          case 'light':
            state = ThemeMode.light;
            break;
          case 'dark':
            state = ThemeMode.dark;
            break;
          case 'system':
          default:
            state = ThemeMode.system;
            break;
        }
      }
    } catch (e) {
      AppLogger.error('[ThemeMode] Error al cargar tema', e);
      // En caso de error, mantener el tema del sistema
      state = ThemeMode.system;
    }
  }

  /// Guarda el modo de tema en SharedPreferences
  Future<void> _saveThemeMode(String theme) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.themeMode, theme);
      AppLogger.debug('[ThemeMode] Tema guardado: $theme');
    } catch (e) {
      AppLogger.error('[ThemeMode] Error al guardar tema', e);
    }
  }

  /// Cambia al tema claro
  void setLightMode() {
    state = ThemeMode.light;
    _saveThemeMode('light');
    AppLogger.info('[ThemeMode] Cambiado a modo claro');
  }

  /// Cambia al tema oscuro
  void setDarkMode() {
    state = ThemeMode.dark;
    _saveThemeMode('dark');
    AppLogger.info('[ThemeMode] Cambiado a modo oscuro');
  }

  /// Cambia al tema del sistema (automático)
  void setSystemMode() {
    state = ThemeMode.system;
    _saveThemeMode('system');
    AppLogger.info('[ThemeMode] Cambiado a modo del sistema');
  }

  /// Alterna entre tema claro y oscuro
  /// Si está en modo sistema, cambia a claro
  void toggleTheme(BuildContext context) {
    // Determinar el tema actual considerando el modo del sistema
    final isDark =
        state == ThemeMode.dark ||
        (state == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    if (isDark) {
      setLightMode();
    } else {
      setDarkMode();
    }

    AppLogger.debug('[ThemeMode] Tema alternado: ${state.name}');
  }

  /// Verifica si el tema actual es oscuro
  bool isDarkMode(BuildContext context) {
    if (state == ThemeMode.dark) return true;
    if (state == ThemeMode.light) return false;

    // Si es system, verificar el tema del sistema
    return MediaQuery.of(context).platformBrightness == Brightness.dark;
  }
}
