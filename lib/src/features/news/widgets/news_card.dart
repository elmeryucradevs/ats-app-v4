import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../models/news_post.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/html_parser.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';

/// Tarjeta de noticia para la lista
///
/// Muestra una vista previa de la noticia con imagen, título,
/// extracto y metadata.
class NewsCard extends StatelessWidget {
  const NewsCard({
    required this.post,
    super.key,
    this.tvId,
    this.tvUpId,
    this.tvDownId,
    this.tvLeftId,
    this.tvRightId,
  });

  final NewsPost post;

  // TV Navigation IDs
  final String? tvId;
  final String? tvUpId;
  final String? tvDownId;
  final String? tvLeftId;
  final String? tvRightId;

  @override
  Widget build(BuildContext context) {
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen destacada
        if (post.featuredImage != null)
          _buildFeaturedImage()
        else
          _buildPlaceholderImage(),

        // Contenido
        Padding(
          padding: const EdgeInsets.all(AppConstants.spacingMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                post.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppConstants.spacingSm),

              // Extracto
              Text(
                HtmlParser.extractPlainText(post.excerpt),
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // Metadata
              _buildMetadata(context),
            ],
          ),
        ),
      ],
    );

    // Si tiene TV ID, usar TVCard para navegación
    if (tvId != null) {
      return TVCard(
        id: tvId!,
        upId: tvUpId,
        downId: tvDownId,
        leftId: tvLeftId,
        rightId: tvRightId,
        margin: EdgeInsets.symmetric(
          horizontal: AppConstants.spacingMd,
          vertical: AppConstants.spacingSm,
        ),
        onTap: () {
          context.push('/news/${post.id}');
        },
        child: cardContent,
      );
    }

    // Fallback a Card normal si no hay TV ID
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/news/${post.id}');
        },
        child: cardContent,
      ),
    );
  }

  Widget _buildFeaturedImage() {
    return Hero(
      tag: 'news_image_${post.id}',
      child: CachedNetworkImage(
        imageUrl: post.featuredImage!,
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          height: 200,
          color: Colors.grey[200],
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => _buildPlaceholderImage(),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[300],
      child: Icon(
        Icons.article_outlined,
        size: AppConstants.iconSizeXl * 2,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    final dateFormat = DateFormat('d MMM yyyy', 'es');
    final formattedDate = dateFormat.format(post.date);
    final readingTime = HtmlParser.estimateReadingTime(post.content);

    return Row(
      children: [
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

        const SizedBox(width: AppConstants.spacingMd),

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

        const Spacer(),

        // Categorías (primera solamente)
        if (post.categories.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.spacingSm,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppConstants.radiusXs),
            ),
            child: Text(
              post.categories.first,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
      ],
    );
  }
}
