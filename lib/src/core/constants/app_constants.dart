/// Constantes globales de la aplicación
///
/// Este archivo centraliza todos los valores constantes utilizados en la app
/// para facilitar el mantenimiento y la consistencia.
library;

/// Constantes de la aplicación
class AppConstants {
  // Constructor privado para evitar instanciación
  AppConstants._();

  // ===================================
  // INFORMACIÓN DE LA APP
  // ===================================
  static const String appName = 'ATESUR';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Tu canal de televisión favorito';

  // ===================================
  // DURATIONS (Duraciones de animaciones)
  // ===================================
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // ===================================
  // SPACING (Espaciados)
  // ===================================
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  static const double spacingXxl = 48.0;

  // ===================================
  // BORDER RADIUS
  // ===================================
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;
  static const double radiusFull = 999.0; // Bordes completamente redondeados

  // ===================================
  // ICONOS (Tamaños)
  // ===================================
  static const double iconSizeXs = 16.0;
  static const double iconSizeSm = 20.0;
  static const double iconSizeMd = 24.0;
  static const double iconSizeLg = 32.0;
  static const double iconSizeXl = 48.0;

  // ===================================
  // PLAYER (Reproductor de video)
  // ===================================
  // Altura del mini reproductor
  static const double miniPlayerHeight = 80.0;

  // Altura máxima del reproductor completo (aspect ratio 16:9)
  static const double maxPlayerHeight = 300.0;

  // Duración para ocultar controles en inactividad
  static const Duration playerControlsHideDelay = Duration(seconds: 3);

  // ===================================
  // NAVEGACIÓN
  // ===================================
  // Altura del BottomNavigationBar
  static const double bottomNavHeight = 60.0;

  // Ancho del NavigationRail en desktop
  static const double navigationRailWidth = 72.0;

  // ===================================
  // BREAKPOINTS (Responsive design)
  // ===================================
  // Breakpoint para considerar "mobile"
  static const double mobileBreakpoint = 600.0;

  // Breakpoint para considerar "tablet"
  static const double tabletBreakpoint = 900.0;

  // Breakpoint para considerar "desktop"
  static const double desktopBreakpoint = 1200.0;

  // ===================================
  // API & CACHE
  // ===================================
  // Tiempo de caché para noticias (15 minutos)
  static const Duration newsCacheDuration = Duration(minutes: 15);

  // Número de noticias por página
  static const int newsPerPage = 10;

  // Timeout para peticiones HTTP
  static const Duration httpTimeout = Duration(seconds: 30);

  // ===================================
  // SCHEDULE (Guía de programación)
  // ===================================
  // Intervalo para actualizar el programa actual
  static const Duration scheduleUpdateInterval = Duration(minutes: 1);

  // Días de la semana
  static const List<String> weekDays = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo',
  ];

  // ===================================
  // SOCIAL MEDIA (Redes sociales)
  // ===================================
  // Iconos predefinidos
  static const String facebookIcon = 'assets/icons/facebook.svg';
  static const String twitterIcon = 'assets/icons/twitter.svg';
  static const String instagramIcon = 'assets/icons/instagram.svg';
  static const String youtubeIcon = 'assets/icons/youtube.svg';
  static const String tiktokIcon = 'assets/icons/tiktok.svg';

  // ===================================
  // VALIDATION (Validación de formularios)
  // ===================================
  // Regex para validar email
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Longitud mínima para nombre
  static const int minNameLength = 2;

  // Longitud mínima para mensaje
  static const int minMessageLength = 10;

  // Longitud máxima para mensaje
  static const int maxMessageLength = 1000;
}

/// Rutas de navegación de la aplicación
class AppRoutes {
  AppRoutes._();

  // Rutas principales
  static const String home = '/';
  static const String player = '/player';
  static const String news = '/news';
  static const String newsDetail = '/news/:id';
  static const String social = '/social';
  static const String contact = '/contact';
  static const String settings = '/settings';
}

/// Claves de storage local
class StorageKeys {
  StorageKeys._();

  // Tema
  static const String themeMode = 'theme_mode';

  // Preferencias del reproductor
  static const String playerVolume = 'player_volume';
  static const String playerAutoplay = 'player_autoplay';

  // Cache
  static const String newsCache = 'news_cache';
  static const String newsCacheTimestamp = 'news_cache_timestamp';

  // Notificaciones
  static const String fcmToken = 'fcm_token';
  static const String notificationsEnabled = 'notifications_enabled';
}
