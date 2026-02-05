import 'package:flutter/material.dart';
import '../../advertising/widgets/smart_banner.dart';
import '../../advertising/models/ad_entities.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:atesur_app_v4/src/core/constants/app_constants.dart';
import '../../../core/services/config_service.dart';

import '../../player/widgets/mini_video_player.dart';
import '../../player/providers/video_player_provider.dart';
import '../../player/providers/pip_provider.dart';
import '../../player/providers/tv_fullscreen_provider.dart';
import '../providers/menu_focus_provider.dart';
import '../../../core/services/platform_service.dart';

// TV Navigation
import 'package:simple_tv_navigation/simple_tv_navigation.dart';

/// Shell principal de la aplicación
///
/// Proporciona el layout base con navegación inferior (BottomNavigationBar)
/// en móvil y NavigationRail en desktop.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({required this.child, super.key});

  /// El contenido de la ruta actual (PlayerScreen, NewsScreen, etc.)
  final Widget child;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  @override
  void initState() {
    super.initState();
    // Initialize ConfigService (RemoteConfig + Supabase)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(configServiceProvider.notifier).initialize().then((_) {
        _checkUpdate();
      });
    });
  }

  void _checkUpdate() {
    final state = ref.read(configServiceProvider);
    if (state.updateRequired) {
      _showUpdateDialog(state.latestVersion);
    }
  }

  void _showUpdateDialog(String? latestVersion) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force update
      builder: (context) => AlertDialog(
        title: const Text('Actualización Requerida'),
        content: Text(
            'Hay una nueva versión disponible ($latestVersion). Por favor actualiza para continuar.'),
        actions: [
          FilledButton(
            onPressed: () {
              // TODO: Replace with real store URL from Config if needed
              launchUrl(Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.atesur.atesur_app_v4'));
            },
            child: const Text('Actualizar Ahora'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Obtener la ubicación actual directamente del router state
    // Esto asegura que el widget se reconstruya cada vez que cambia la ruta
    final String location = GoRouterState.of(context).uri.path;
    final int currentIndex = _getIndexFromLocation(location);

    // Mostrar mini player solo cuando NO estamos en la pantalla principal (índice 0)
    final bool showMiniPlayer = currentIndex != 0;

    // Sincronizar estado del player con la ruta actual
    // Usamos addPostFrameCallback para evitar modificar providers durante el build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final playerState = ref.read(videoPlayerProvider);

      // Si deberíamos mostrar el mini player (index != 0) pero no está minimizado...
      if (showMiniPlayer && !playerState.isMinimized) {
        ref.read(videoPlayerProvider.notifier).minimizePlayer();
      }
      // Si estamos en home (index == 0) y está minimizado...
      else if (!showMiniPlayer && playerState.isMinimized) {
        ref.read(videoPlayerProvider.notifier).maximizePlayer();
      }
    });

    // Check PiP mode from global provider
    final isPipMode = ref.watch(pipProvider);

    // Check TV Fullscreen mode (from PlayerScreen)
    final isTvFullscreen = ref.watch(tvFullscreenProvider);

    // If in PiP mode or TV Fullscreen, return only child (no layout shell)
    if (isPipMode || isTvFullscreen) {
      return widget.child;
    }

    // Initialize Platform detection
    ref.watch(platformInitializerProvider);
    final isTvDetected = ref.watch(isTvProvider);

    // Detectar si es TV (Navegación direccional O detectado por PlatformService)
    final isTv =
        MediaQuery.of(context).navigationMode == NavigationMode.directional ||
            isTvDetected;

    final isWideLayout =
        MediaQuery.of(context).size.width >= AppConstants.desktopBreakpoint ||
            isTv;

    // Layout para desktop/TV usa NavigationRail
    if (isWideLayout) {
      return _DesktopLayout(
        currentIndex: currentIndex,
        showMiniPlayer: showMiniPlayer,
        child: widget.child,
      );
    }

    // Layout para móvil/tablet usa BottomNavigationBar
    return _MobileLayout(
      currentIndex: currentIndex,
      showMiniPlayer: showMiniPlayer,
      child: widget.child,
    );
  }

  int _getIndexFromLocation(String location) {
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/news')) return 2;
    if (location.startsWith('/social')) return 3;
    if (location.startsWith('/contact')) return 4;
    return 0; // Home por defecto
  }
}

// ===================================
// LAYOUT MÓVIL (BottomNavigationBar)
// ===================================

class _MobileLayout extends ConsumerWidget {
  const _MobileLayout({
    required this.currentIndex,
    required this.showMiniPlayer,
    required this.child,
  });

  final int currentIndex;
  final bool showMiniPlayer;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      // El contenido de la ruta actual con Stack para mini player
      body: Column(
        children: [
          const SmartBanner(position: AdPosition.top), // Banner Global Top
          Expanded(
            child: Stack(
              children: [
                child,
                if (showMiniPlayer)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: MiniVideoPlayer(onTap: () => context.go('/')),
                  ),
              ],
            ),
          ),
          const SmartBanner(
              position: AdPosition.bottom), // Banner Global Bottom
        ],
      ),

      // Barra de navegación inferior
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) => _onItemTapped(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Guía',
          ),
          NavigationDestination(
            icon: Icon(Icons.newspaper_outlined),
            selectedIcon: Icon(Icons.newspaper),
            label: 'Noticias',
          ),
          NavigationDestination(
            icon: Icon(Icons.share_outlined),
            selectedIcon: Icon(Icons.share),
            label: 'Redes',
          ),
          NavigationDestination(
            icon: Icon(Icons.contact_mail_outlined),
            selectedIcon: Icon(Icons.contact_mail),
            label: 'Contacto',
          ),
        ],
      ),
    );
  }
}

// ===================================
// LAYOUT DESKTOP (NavigationRail)
// ===================================

class _DesktopLayout extends ConsumerStatefulWidget {
  const _DesktopLayout({
    required this.currentIndex,
    required this.showMiniPlayer,
    required this.child,
  });

  final int currentIndex;
  final bool showMiniPlayer;
  final Widget child;

  @override
  ConsumerState<_DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends ConsumerState<_DesktopLayout> {
  @override
  Widget build(BuildContext context) {
    // Escuchar solicitudes de foco desde el provider
    ref.listen(menuFocusControllerProvider, (_, __) {
      if (mounted) {
        // Usar navegación TV para enfocar el sidebar
        context.setFocus('nav_${widget.currentIndex}');
      }
    });

    return Scaffold(
      body: Row(
        children: [
          // Sidebar con TVFocusable para navegación TV
          Container(
            width: 80,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildNavItem(
                  context: context,
                  id: 'nav_0',
                  icon: Icons.play_circle_outline,
                  selectedIcon: Icons.play_circle,
                  label: 'Inicio',
                  index: 0,
                  isSelected: widget.currentIndex == 0,
                  upId: null, // Primer elemento
                  downId: 'nav_1',
                  rightId:
                      'player_fullscreen', // Al presionar derecha, ir al contenido
                ),
                _buildNavItem(
                  context: context,
                  id: 'nav_1',
                  icon: Icons.calendar_today_outlined,
                  selectedIcon: Icons.calendar_today,
                  label: 'Guía',
                  index: 1,
                  isSelected: widget.currentIndex == 1,
                  upId: 'nav_0',
                  downId: 'nav_2',
                  rightId: 'schedule_date_0', // Primer chip de fecha
                ),
                _buildNavItem(
                  context: context,
                  id: 'nav_2',
                  icon: Icons.newspaper_outlined,
                  selectedIcon: Icons.newspaper,
                  label: 'Noticias',
                  index: 2,
                  isSelected: widget.currentIndex == 2,
                  upId: 'nav_1',
                  downId: 'nav_3',
                  rightId: 'news_search', // Botón de búsqueda
                ),
                _buildNavItem(
                  context: context,
                  id: 'nav_3',
                  icon: Icons.share_outlined,
                  selectedIcon: Icons.share,
                  label: 'Redes',
                  index: 3,
                  isSelected: widget.currentIndex == 3,
                  upId: 'nav_2',
                  downId: 'nav_4',
                  rightId: 'social_card_0', // Primera card social
                ),
                _buildNavItem(
                  context: context,
                  id: 'nav_4',
                  icon: Icons.contact_mail_outlined,
                  selectedIcon: Icons.contact_mail,
                  label: 'Contacto',
                  index: 4,
                  isSelected: widget.currentIndex == 4,
                  upId: 'nav_3',
                  downId: null, // Último elemento
                  rightId: 'contact_email', // ListTile de email
                ),
              ],
            ),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // Contenido principal con Publicidad Lateral y Top/Bottom
          Expanded(
            child: Column(
              children: [
                const SmartBanner(
                    position: AdPosition.top), // Banner GLOBAL Top
                Expanded(
                  child: Row(
                    children: [
                      const SmartBanner(
                          position: AdPosition.left_sidebar), // Sidebar IZQ
                      Expanded(
                        child: Stack(
                          children: [
                            widget.child,
                            if (widget.showMiniPlayer)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: MiniVideoPlayer(
                                    onTap: () => context.go('/')),
                              ),
                          ],
                        ),
                      ),
                      const SmartBanner(
                          position: AdPosition.right_sidebar), // Sidebar DER
                    ],
                  ),
                ),
                const SmartBanner(
                    position: AdPosition.bottom), // Banner GLOBAL Bottom
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un ítem de navegación con TVFocusable
  Widget _buildNavItem({
    required BuildContext context,
    required String id,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
    String? upId,
    String? downId,
    String? rightId,
  }) {
    return TVFocusable(
      id: id,
      upId: upId,
      downId: downId,
      rightId: rightId,
      leftId: null, // No hay nada a la izquierda del sidebar
      showDefaultFocusDecoration: true, // Mostrar decoración de foco visual
      onSelect: () => _onItemTapped(context, index),
      builder: (context, isFocused, child) {
        // Wrap with GestureDetector for web/mouse click support
        return GestureDetector(
          onTap: () => _onItemTapped(context, index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 80,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isFocused
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                  : (isSelected
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : Colors.transparent),
              border: isFocused
                  ? Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    )
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  size: isFocused ? 28 : 24,
                  color: isSelected || isFocused
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isFocused ? 11 : 10,
                    fontWeight: isFocused ? FontWeight.bold : FontWeight.normal,
                    color: isSelected || isFocused
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===================================
// NAVEGACIÓN
// ===================================

/// Maneja la navegación cuando se toca un ítem
void _onItemTapped(BuildContext context, int index) {
  // Navegar según el índice
  switch (index) {
    case 0:
      context.go('/');
      break;
    case 1:
      context.go('/schedule');
      break;
    case 2:
      context.go('/news');
      break;
    case 3:
      context.go('/social');
      break;
    case 4:
      context.go('/contact');
      break;
  }
}
