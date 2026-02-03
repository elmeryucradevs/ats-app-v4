import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/news_post.dart';
import '../models/news_response.dart';
import '../services/news_service.dart';

/// Provider del servicio de noticias
final newsServiceProvider = Provider<NewsService>((ref) {
  final service = NewsService();
  service.initialize();
  return service;
});

/// Provider para obtener la lista de noticias con paginación
///
/// [page] Número de página a obtener
final newsListProvider = FutureProvider.family<NewsResponse, int>((
  ref,
  page,
) async {
  final service = ref.watch(newsServiceProvider);
  return service.fetchPosts(page: page, perPage: 10);
});

/// Provider para obtener una noticia específica por ID
///
/// [postId] ID del post a obtener
final newsDetailProvider = FutureProvider.family<NewsPost, int>((
  ref,
  postId,
) async {
  final service = ref.watch(newsServiceProvider);
  return service.fetchPostById(postId);
});

/// Provider para búsqueda de noticias
///
/// [query] Término de búsqueda
final newsSearchProvider = FutureProvider.family<NewsResponse, String>((
  ref,
  query,
) async {
  final service = ref.watch(newsServiceProvider);
  return service.searchPosts(query: query);
});

/// Provider para refrescar la lista de noticias
final refreshNewsProvider = Provider<void Function()>((ref) {
  return () {
    // Invalidar el provider de la primera página
    ref.invalidate(newsListProvider(1));
  };
});
