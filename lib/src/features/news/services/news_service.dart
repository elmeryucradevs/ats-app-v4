import '../models/news_post.dart';
import '../models/news_response.dart';
import '../../../core/services/http_service.dart';
import '../../../core/utils/app_logger.dart';

/// Servicio para obtener noticias desde WordPress REST API
///
/// Maneja la comunicación con la API de WordPress.com para
/// obtener posts/noticias del sitio atesurplus.wordpress.com.
class NewsService {
  static final NewsService _instance = NewsService._internal();
  factory NewsService() => _instance;
  NewsService._internal();

  final HttpService _http = HttpService();

  /// Base URL de la API de WordPress.com
  static const String _baseUrl = 'https://public-api.wordpress.com/rest/v1.1';

  /// ID del sitio de WordPress
  static const String _siteId = '246715462';

  /// Inicializa el servicio
  void initialize() {
    _http.initialize(baseUrl: _baseUrl);
    AppLogger.info('[NewsService] Servicio inicializado');
  }

  /// Obtiene una lista de posts con paginación
  ///
  /// [page] Número de página (empezando en 1)
  /// [perPage] Cantidad de posts por página (default: 10)
  Future<NewsResponse> fetchPosts({int page = 1, int perPage = 10}) async {
    try {
      AppLogger.debug(
        '[NewsService] Obteniendo posts: page=$page, perPage=$perPage',
      );

      final offset = (page - 1) * perPage;

      final response = await _http.get(
        '/sites/$_siteId/posts/',
        queryParameters: {
          'number': perPage,
          'offset': offset,
          'fields':
              'ID,title,excerpt,content,date,author,featured_image,categories',
        },
      );

      if (response.data == null) {
        AppLogger.warning('[NewsService] Respuesta vacía de la API');
        return NewsResponse.empty;
      }

      final newsResponse = NewsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      AppLogger.info(
        '[NewsService] ✅ Obtenidos ${newsResponse.posts.length} posts',
      );

      return newsResponse;
    } catch (e, stackTrace) {
      AppLogger.error('[NewsService] Error al obtener posts', e, stackTrace);
      rethrow;
    }
  }

  /// Obtiene un post específico por ID
  ///
  /// [postId] ID del post a obtener
  Future<NewsPost> fetchPostById(int postId) async {
    try {
      AppLogger.debug('[NewsService] Obteniendo post ID: $postId');

      final response = await _http.get(
        '/sites/$_siteId/posts/$postId',
        queryParameters: {
          'fields':
              'ID,title,excerpt,content,date,author,featured_image,categories',
        },
      );

      if (response.data == null) {
        throw Exception('Post no encontrado');
      }

      final post = NewsPost.fromJson(response.data as Map<String, dynamic>);
      AppLogger.info('[NewsService] ✅ Post obtenido: ${post.title}');

      return post;
    } catch (e, stackTrace) {
      AppLogger.error(
        '[NewsService] Error al obtener post $postId',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Busca posts por término
  ///
  /// [query] Término de búsqueda
  /// [page] Número de página
  /// [perPage] Posts por página
  Future<NewsResponse> searchPosts({
    required String query,
    int page = 1,
    int perPage = 10,
  }) async {
    try {
      AppLogger.debug('[NewsService] Buscando posts: "$query"');

      final offset = (page - 1) * perPage;

      final response = await _http.get(
        '/sites/$_siteId/posts/',
        queryParameters: {
          'search': query,
          'number': perPage,
          'offset': offset,
          'fields':
              'ID,title,excerpt,content,date,author,featured_image,categories',
        },
      );

      if (response.data == null) {
        return NewsResponse.empty;
      }

      final newsResponse = NewsResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
      AppLogger.info(
        '[NewsService] ✅ Encontrados ${newsResponse.posts.length} posts',
      );

      return newsResponse;
    } catch (e, stackTrace) {
      AppLogger.error('[NewsService] Error en búsqueda', e, stackTrace);
      rethrow;
    }
  }
}
