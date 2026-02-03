import 'package:flutter/material.dart';

/// Modelo para un enlace de red social
///
/// Representa una red social con su información visual y URL.
class SocialLink {
  /// Nombre de la red social
  final String name;

  /// URL del perfil
  final String url;

  /// Icono de Material Icons
  final IconData icon;

  /// Color representativo de la red social
  final Color color;

  const SocialLink({
    required this.name,
    required this.url,
    required this.icon,
    required this.color,
  });

  /// Indica si el link está disponible (URL no vacía)
  bool get isAvailable => url.isNotEmpty;

  @override
  String toString() => 'SocialLink(name: $name, url: $url)';
}
