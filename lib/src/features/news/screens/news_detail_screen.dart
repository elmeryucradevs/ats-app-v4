import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/news_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/html_parser.dart' as app_html;
import '../../../core/widgets/tv_focusable_widgets.dart';
import '../../../core/services/platform_service.dart';

/// Pantalla de detalle de una noticia
///
/// Muestra el contenido completo de un post de WordPress
class NewsDetailScreen extends ConsumerWidget {
  const NewsDetailScreen({required this.postId, super.key});

  final int postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postAsync = ref.watch(newsDetailProvider(postId));
    final isTv = ref.watch(isTvProvider);

    return Scaffold(
      body: postAsync.when(
        data: (post) => CustomScrollView(
          slivers: [
            // AppBar con imagen de fondo
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              // En TV, hacer el botón de volver focusable
              leading: isTv
                  ? TVIconButton(
                      id: 'news_detail_back',
                      downId: 'news_detail_content',
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.of(context).pop(),
                    )
                  : null,
              flexibleSpace: FlexibleSpaceBar(
                background: post.featuredImage != null
                    ? Hero(
                        tag: 'news_image_$postId',
                        child: CachedNetworkImage(
                          imageUrl: post.featuredImage!,
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: Icon(
                              Icons.article_outlined,
                              size: AppConstants.iconSizeXl * 2,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: Icon(
                          Icons.article_outlined,
                          size: AppConstants.iconSizeXl * 2,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),

            // Contenido - en TV, envuelto en TVCard para navegación
            SliverToBoxAdapter(
              child: isTv
                  ? TVCard(
                      id: 'news_detail_content',
                      upId: 'news_detail_back',
                      downId: 'news_detail_share',
                      margin: EdgeInsets.zero,
                      child: _buildContent(context, post),
                    )
                  : _buildContent(context, post),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) =>
            _buildErrorState(context, ref, error.toString(), isTv),
      ),
    );
  }

  Widget _buildContent(BuildContext context, post) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Categorías
          if (post.categories.isNotEmpty) ...[
            Wrap(
              spacing: AppConstants.spacingSm,
              children: post.categories.take(3).map<Widget>((category) {
                return Chip(
                  label: Text(
                    category,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                );
              }).toList(),
            ),
            const SizedBox(height: AppConstants.spacingMd),
          ],

          // Título
          Text(
            post.title,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: AppConstants.spacingMd),

          // Metadata
          _buildMetadata(context, post),

          const Divider(height: AppConstants.spacingXl),

          // Contenido HTML
          Html(
            data: app_html.HtmlParser.cleanHtml(post.content),
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
              ),
              'p': Style(
                fontSize: FontSize(16),
                lineHeight: const LineHeight(1.6),
                margin: Margins.only(bottom: 16),
              ),
              'h1, h2, h3, h4, h5, h6': Style(
                fontWeight: FontWeight.bold,
                margin: Margins.only(top: 16, bottom: 8),
              ),
              'img': Style(
                width: Width.auto(),
                height: Height.auto(),
                margin: Margins.symmetric(vertical: 16),
              ),
              'a': Style(
                color: Theme.of(context).colorScheme.primary,
                textDecoration: TextDecoration.underline,
              ),
            },
            onLinkTap: (url, attributes, element) {
              if (url != null) {
                _launchUrl(url);
              }
            },
          ),

          const SizedBox(height: AppConstants.spacingXl),

          // Botón compartir - usar TVButton en TV mode (se maneja en parent)
          _buildShareButton(context, post),

          const SizedBox(height: AppConstants.spacingLg),
        ],
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, post) {
    // El botón de compartir siempre usa OutlinedButton ya que el contenido
    // entero está envuelto en TVCard y puede hacer scroll
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _sharePost(post),
        icon: const Icon(Icons.share),
        label: const Text('Compartir'),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context, post) {
    final dateFormat = DateFormat('d MMMM yyyy, HH:mm', 'es');
    final formattedDate = dateFormat.format(post.date);
    final readingTime = app_html.HtmlParser.estimateReadingTime(post.content);

    return Row(
      children: [
        // Autor
        Icon(
          Icons.person_outline,
          size: AppConstants.iconSizeSm,
          color: Colors.grey[600],
        ),
        const SizedBox(width: AppConstants.spacingXs),
        Text(
          post.authorName,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),

        const SizedBox(width: AppConstants.spacingMd),

        // Fecha
        Icon(
          Icons.calendar_today_outlined,
          size: AppConstants.iconSizeSm,
          color: Colors.grey[600],
        ),
        const SizedBox(width: AppConstants.spacingXs),
        Text(
          formattedDate,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),

        const Spacer(),

        // Tiempo de lectura
        Icon(
          Icons.access_time_outlined,
          size: AppConstants.iconSizeSm,
          color: Colors.grey[600],
        ),
        const SizedBox(width: AppConstants.spacingXs),
        Text(
          '$readingTime min',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, String error, bool isTv) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        leading: isTv
            ? TVIconButton(
                id: 'news_error_back',
                downId: 'news_error_retry',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacingLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: AppConstants.iconSizeXl * 2,
                color: Colors.red,
              ),
              const SizedBox(height: AppConstants.spacingLg),
              const Text(
                'Error al cargar la noticia',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Text(
                error,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.spacingLg),
              if (isTv)
                TVButton(
                  id: 'news_error_retry',
                  upId: 'news_error_back',
                  onPressed: () {
                    ref.invalidate(newsDetailProvider(postId));
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh),
                      SizedBox(width: 8),
                      Text('Reintentar'),
                    ],
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(newsDetailProvider(postId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Comparte el post usando share_plus
  void _sharePost(dynamic post) {
    final shareText = '''
${post.title}

${app_html.HtmlParser.extractPlainText(post.excerpt)}

Lee más en la app ATESUR
''';

    SharePlus.instance.share(ShareParams(text: shareText, subject: post.title));
  }

  Future<void> _launchUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
