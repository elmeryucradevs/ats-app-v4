import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Core
import 'src/core/theme/app_theme.dart';
import 'src/core/theme/theme_provider.dart';
import 'src/core/router/app_router.dart';
import 'src/core/config/env_config.dart';
import 'src/core/services/supabase_service.dart';
import 'src/core/services/notification_service.dart';
import 'src/core/services/inapp_message_service.dart';
import 'src/core/utils/app_logger.dart';
import 'src/features/schedule/services/local_notification_service.dart';
import 'src/features/schedule/services/alarm_callback_service.dart';
import 'src/features/player/services/chromecast_service.dart';
import 'src/features/inapp/widgets/inapp_message_listener.dart';
import 'src/features/advertising/widgets/startup_interstitial.dart';

// TV Navigation
import 'package:simple_tv_navigation/simple_tv_navigation.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Intl for date formatting
import 'package:intl/date_symbol_data_local.dart';

/// Punto de entrada de la aplicación
///
/// Inicializa todos los servicios necesarios antes de ejecutar la app.
void main() async {
  // Asegurar que los bindings de Flutter estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('🚀 [Main] Iniciando ATESUR App v4...');

  // Cargar variables de entorno
  // En web, usa --dart-define; en móvil/desktop usa .env
  if (!kIsWeb) {
    try {
      await dotenv.load(fileName: '.env');
      AppLogger.info('[Main] ✅ Variables de entorno cargadas desde .env');
    } catch (e) {
      AppLogger.warning(
        '[Main] ⚠️ No se pudo cargar .env, usando valores por defecto',
      );
    }
  } else {
    AppLogger.info('[Main] 🌐 Modo web: usando --dart-define o fallbacks');
  }

  // Validar configuración
  EnvConfig.validate();
  if (EnvConfig.debugMode) {
    EnvConfig.printConfig();
  }

  // ===================================
  // 2. INICIALIZAR SUPABASE
  // ===================================
  final supabaseInitialized = await SupabaseService.initialize();
  if (!supabaseInitialized) {
    AppLogger.warning(
      '[Main] ⚠️ Supabase no inicializado. Funcionalidades limitadas.',
    );
  }

  // ===================================
  // 3. INICIALIZAR CHROMECAST SERVICE
  // ===================================
  try {
    AppLogger.info('[Main] 📺 Inicializando ChromecastService...');
    // Se inicializa el servicio para iniciar el discovery y los listeners
    await ChromecastService().initialize();
    AppLogger.info('[Main] ✅ ChromecastService inicializado');
  } catch (e) {
    AppLogger.warning('[Main] ⚠️ Error al inicializar ChromecastService: $e');
  }

  // ===================================
  // 4. INICIALIZAR FIREBASE (FCM)
  // ===================================
  try {
    AppLogger.info('[Main] 🔥 Inicializando Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('[Main] ✅ Firebase inicializado');

    // Inicializar servicio de notificaciones
    AppLogger.info('[Main] 🔔 Inicializando NotificationService...');
    await NotificationService.instance.initialize();
    AppLogger.info('[Main] ✅ NotificationService inicializado');
  } catch (e, stackTrace) {
    AppLogger.error(
      '[Main] ❌ Error al inicializar Firebase/FCM',
      e,
      stackTrace,
    );
    AppLogger.warning('[Main]   La app funcionará sin notificaciones push');
  }

  // ===================================
  // 4. INICIALIZAR NOTIFICACIONES LOCALES
  // ===================================
  try {
    AppLogger.info('[Main] ⏰ Inicializando LocalNotificationService...');
    await LocalNotificationService().initialize();
    AppLogger.info('[Main] ✅ LocalNotificationService inicializado');

    // Initialize AndroidAlarmManager for background alarms (Android only)
    if (!kIsWeb) {
      await AlarmCallbackService.initialize();
      AppLogger.info('[Main] ✅ AndroidAlarmManager inicializado');
    }
  } catch (e) {
    AppLogger.error('[Main] ⚠️ Error al inicializar notificaciones locales', e);
  }

  // ===================================
  // 6. INICIALIZAR IN-APP MESSAGING
  // ===================================
  try {
    AppLogger.info('[Main] 💬 Inicializando InAppMessageService...');
    await InAppMessageService().initialize();
    AppLogger.info('[Main] ✅ InAppMessageService inicializado');
  } catch (e) {
    AppLogger.warning('[Main] ⚠️ Error al inicializar InAppMessageService: $e');
  }

  // ===================================
  // 7. INICIALIZAR FORMATEO DE FECHAS
  // ===================================
  try {
    await initializeDateFormatting('es', null);
    AppLogger.info('[Main] ✅ Locale de fechas inicializado (es)');
  } catch (e) {
    AppLogger.warning('[Main] ⚠️ Error al inicializar locale de fechas: $e');
  }

  // ===================================
  // 8. DESHABILITAR WAKELOCK
  // ===================================
  // El wakelock se habilitará automáticamente cuando se reproduzca video
  WakelockPlus.disable();

  AppLogger.info('[Main] ✅ Inicialización completada. Lanzando app...');

  // ===================================
  // 9. EJECUTAR APLICACIÓN
  // ===================================
  runApp(
    // ProviderScope de Riverpod - Gestión de estado global
    const ProviderScope(child: MyApp()),
  );
}

/// Widget principal de la aplicación
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observar el tema actual
    final themeMode = ref.watch(themeModeProvider);

    // Observar el router
    final router = ref.watch(goRouterProvider);

    // Wrap with TvNavigationProvider for TV D-pad navigation
    return TvNavigationProvider(
      child: MaterialApp.router(
        // ===================================
        // CONFIGURACIÓN BÁSICA
        // ===================================
        title: EnvConfig.channelName,
        debugShowCheckedModeBanner: false,

        // ===================================
        // TEMAS
        // ===================================
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,

        // ===================================
        // ROUTER (Navegación)
        // ===================================
        routerConfig: router,

        // ===================================
        // BUILDER (In-App Messages + Overlays)
        // ===================================
        builder: (context, child) {
          return StartupInterstitial(
            // Publicidad Global al Inicio
            child: InAppMessageListener(
              child: Stack(
                children: [
                  // La aplicación principal
                  child!,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
