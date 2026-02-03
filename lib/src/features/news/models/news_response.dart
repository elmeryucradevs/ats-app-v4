import 'news_post.dart';

/// Respuesta paginada de la API de WordPress
///
/// Contiene una lista de posts y metadatos de paginación.
class NewsResponse {
  /// Lista de posts en esta página
  final List<NewsPost> posts;

  /// Total de posts encontrados (para paginación)
  final int totalFound;

  /// Indica si hay más posts disponibles
  final bool hasMore;

  const NewsResponse({
    required this.posts,
    required this.totalFound,
    required this.hasMore,
  });

  /// Crea un NewsResponse desde JSON de WordPress API
  factory NewsResponse.fromJson(Map<String, dynamic> json) {
    final postsList =
        (json['posts'] as List<dynamic>?)
            ?.map((post) => NewsPost.fromJson(post as Map<String, dynamic>))
            .toList() ??
        [];

    final found = json['found'] as int? ?? 0;

    return NewsResponse(
      posts: postsList,
      totalFound: found,
      hasMore: postsList.length < found,
    );
  }

  /// Convierte el NewsResponse a JSON
  Map<String, dynamic> toJson() {
    return {
      'posts': posts.map((post) => post.toJson()).toList(),
      'found': totalFound,
    };
  }

  /// Respuesta vacía
  static const empty = NewsResponse(posts: [], totalFound: 0, hasMore: false);

  @override
  String toString() =>
      'NewsResponse(posts: ${posts.length}, total: $totalFound, hasMore: $hasMore)';
}
