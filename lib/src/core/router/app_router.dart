import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Screens
import '../../features/player/screens/player_screen.dart';
import '../../features/news/screens/news_screen.dart';
import '../../features/news/screens/news_detail_screen.dart';
import '../../features/social/screens/social_screen.dart';
import '../../features/contact/screens/contact_screen.dart';
import '../../features/notifications/screens/notification_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';
import '../../features/shell/screens/main_shell.dart';

/// Global navigator key for showing dialogs from anywhere (e.g., InAppMessageService)
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

/// Configuración global del router de la aplicación
///
/// Utiliza go_router para navegación declarativa compatible con web.
/// Incluye shell navigation para mantener el BottomNavigationBar visible.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey, // Use global key
    debugLogDiagnostics: true, // Logs en modo debug
    initialLocation: '/',

    // ===================================
    // RUTAS PRINCIPALES
    // ===================================
    routes: [
      // Shell route - Contiene las rutas principales con navegación persistente
      ShellRoute(
        builder: (context, state, child) {
          return MainShell(child: child);
        },
        routes: [
          // Ruta: Inicio / Reproductor (/)
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const PlayerScreen(),
            ),
          ),

          // Ruta: Noticias (/news)
          GoRoute(
            path: '/news',
            name: 'news',
            pageBuilder: (context, state) =>
                NoTransitionPage(key: state.pageKey, child: const NewsScreen()),
            // Sub-ruta: Detalle de noticia (/news/:id)
            routes: [
              GoRoute(
                path: ':id',
                name: 'newsDetail',
                builder: (context, state) {
                  final postIdString = state.pathParameters['id']!;
                  final postId = int.parse(postIdString);
                  return NewsDetailScreen(postId: postId);
                },
              ),
            ],
          ),

          // Ruta: Redes Sociales (/social)
          GoRoute(
            path: '/social',
            name: 'social',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const SocialScreen(),
            ),
          ),

          // Ruta: Contacto (/contact)
          GoRoute(
            path: '/contact',
            name: 'contact',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ContactScreen(),
            ),
          ),

          // Ruta: Notificaciones (/notifications)
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const NotificationScreen(),
            ),
          ),

          // Ruta: Programación (/schedule)
          GoRoute(
            path: '/schedule',
            name: 'schedule',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ScheduleScreen(),
            ),
          ),
        ],
      ),
    ],

    // ===================================
    // MANEJO DE ERRORES
    // ===================================
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Página no encontrada',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ruta: ${state.uri}',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text('Volver al inicio'),
              ),
            ],
          ),
        ),
      );
    },

    // ===================================
    // REDIRECCIONES
    // ===================================
    // Útil para redireccionar rutas antiguas o manejar autenticación
    redirect: (context, state) {
      // Por ahora no hay redirecciones
      // Aquí podrías agregar lógica de autenticación si fuera necesario
      return null;
    },
  );
});

/// Provider para obtener la ubicación actual del router
final currentLocationProvider = Provider<String>((ref) {
  final router = ref.watch(goRouterProvider);
  return router.routeInformationProvider.value.uri.path;
});
