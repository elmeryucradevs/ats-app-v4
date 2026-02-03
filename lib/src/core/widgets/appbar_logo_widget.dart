import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../services/config_service.dart';

/// Widget que muestra el logo del canal en el AppBar
/// con skeleton loading (shimmer) y cache de imagen.
///
/// Características:
/// - Usa CachedNetworkImage para cachear el logo localmente
/// - Muestra un shimmer placeholder mientras carga
/// - Si no hay logo o hay error, muestra el texto de fallback
/// - Se actualiza automáticamente cuando cambia el logo en Supabase (Realtime)
class AppBarLogoWidget extends ConsumerWidget {
  /// Altura del logo (ancho se calcula automáticamente)
  final double height;

  /// Texto a mostrar si no hay logo o si falla la carga
  final String? fallbackText;

  /// Duración de la animación de fade in
  final Duration fadeInDuration;

  const AppBarLogoWidget({
    super.key,
    this.height = 32,
    this.fallbackText,
  }) : fadeInDuration = const Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar cambios en la configuración (incluye Realtime de Supabase)
    final config = ref.watch(configServiceProvider);
    final logoUrl = config.logoUrl;

    // Si no hay URL de logo, mostrar texto de fallback
    if (logoUrl.isEmpty) {
      return _buildFallbackText(context);
    }

    return CachedNetworkImage(
      imageUrl: logoUrl,
      height: height,
      fit: BoxFit.contain,
      // Placeholder: Shimmer skeleton mientras carga
      placeholder: (context, url) => _buildShimmerPlaceholder(context),
      // Error: Mostrar texto de fallback si falla la carga
      errorWidget: (context, url, error) => _buildFallbackText(context),
      // Animación de fade in cuando la imagen carga
      fadeInDuration: fadeInDuration,
      fadeOutDuration: const Duration(milliseconds: 100),
      // Usar memoria cache además de disco
      memCacheHeight: (height * 2).toInt(), // 2x para pantallas HiDPI
    );
  }

  /// Construye el placeholder shimmer mientras carga el logo
  Widget _buildShimmerPlaceholder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(
        height: height,
        width: height * 3, // Ancho aproximado del logo
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  /// Construye el texto de fallback cuando no hay logo
  Widget _buildFallbackText(BuildContext context) {
    if (fallbackText == null || fallbackText!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Text(
      fallbackText!,
      style: Theme.of(context).appBarTheme.titleTextStyle,
    );
  }
}
