/// Modelo de un post de noticias desde WordPress
///
/// Representa un artículo/noticia obtenido desde la API REST de WordPress.
class NewsPost {
  /// ID único del post
  final int id;

  /// Título del post
  final String title;

  /// Extracto/resumen del post (puede contener HTML)
  final String excerpt;

  /// Contenido completo del post (HTML)
  final String content;

  /// Fecha de publicación
  final DateTime date;

  /// Nombre del autor
  final String authorName;

  /// URL de la imagen destacada
  final String? featuredImage;

  /// Lista de categorías del post
  final List<String> categories;

  const NewsPost({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.content,
    required this.date,
    required this.authorName,
    this.featuredImage,
    required this.categories,
  });

  /// Crea un NewsPost desde JSON de WordPress API
  factory NewsPost.fromJson(Map<String, dynamic> json) {
    // Extraer featured_image: puede ser string directo o un objeto con 'uri'
    String? featuredImageUrl;
    final featuredImageData = json['featured_image'];

    if (featuredImageData is String && featuredImageData.isNotEmpty) {
      featuredImageUrl = featuredImageData;
    } else if (featuredImageData is Map<String, dynamic>) {
      // WordPress a veces devuelve un objeto con uri, URL, o link
      featuredImageUrl =
          featuredImageData['uri'] as String? ??
          featuredImageData['URL'] as String? ??
          featuredImageData['link'] as String?;
    }

    // Proxy para evitar CORS en web
    if (featuredImageUrl != null && featuredImageUrl.isNotEmpty) {
      featuredImageUrl = _proxifyImageUrl(featuredImageUrl);
    }

    return NewsPost(
      id: json['ID'] as int,
      title: json['title'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      content: json['content'] as String? ?? '',
      date: DateTime.parse(json['date'] as String),
      authorName: json['author']?['name'] as String? ?? 'Desconocido',
      featuredImage: featuredImageUrl,
      categories:
          (json['categories'] as Map<String, dynamic>?)?.keys.toList() ?? [],
    );
  }

  /// Proxy para imágenes de WordPress para evitar CORS en web
  static String _proxifyImageUrl(String originalUrl) {
    // Usar wsrv.nl como proxy CORS-friendly
    // Esto permite cargar imágenes de WordPress en localhost
    return 'https://wsrv.nl/?url=${Uri.encodeComponent(originalUrl)}&w=800&output=webp';
  }

  /// Convierte el NewsPost a JSON
  Map<String, dynamic> toJson() {
    return {
      'ID': id,
      'title': title,
      'excerpt': excerpt,
      'content': content,
      'date': date.toIso8601String(),
      'author': {'name': authorName},
      'featured_image': featuredImage,
      'categories': {for (var cat in categories) cat: {}},
    };
  }

  /// Copia el post con algunos campos modificados
  NewsPost copyWith({
    int? id,
    String? title,
    String? excerpt,
    String? content,
    DateTime? date,
    String? authorName,
    String? featuredImage,
    List<String>? categories,
  }) {
    return NewsPost(
      id: id ?? this.id,
      title: title ?? this.title,
      excerpt: excerpt ?? this.excerpt,
      content: content ?? this.content,
      date: date ?? this.date,
      authorName: authorName ?? this.authorName,
      featuredImage: featuredImage ?? this.featuredImage,
      categories: categories ?? this.categories,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NewsPost && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'NewsPost(id: $id, title: $title)';
}
