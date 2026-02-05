import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';
import '../widgets/news_card_skeleton.dart';
import '../widgets/news_search_delegate.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';
import '../../advertising/widgets/smart_banner.dart';
import '../../advertising/models/ad_entities.dart';

/// Pantalla principal de noticias
///
/// Muestra una lista de noticias desde WordPress con:
/// - Pull-to-refresh
/// - Skeleton loaders
/// - Estados de carga, error y vacío
class NewsScreen extends ConsumerStatefulWidget {
  const NewsScreen({super.key});

  @override
  ConsumerState<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends ConsumerState<NewsScreen> {
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsListProvider(_currentPage));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Noticias'),
        actions: [
          // TVIconButton para navegación TV
          TVIconButton(
            id: 'news_search',
            leftId: 'nav_2', // Volver al sidebar
            downId: 'news_card_0', // Ir a primera noticia
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(context: context, delegate: NewsSearchDelegate(ref));
            },
            tooltip: 'Buscar',
          ),
        ],
      ),
      body: newsAsync.when(
        data: (newsResponse) {
          if (newsResponse.posts.isEmpty) {
            return _buildEmptyState();
          }

          final totalItems =
              newsResponse.posts.length + (newsResponse.hasMore ? 1 : 0);

          return RefreshIndicator(
            onRefresh: () async {
              // Refrescar primera página
              setState(() {
                _currentPage = 1;
              });
              ref.invalidate(newsListProvider(_currentPage));
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: AppConstants.spacingSm,
              ),
              itemCount: totalItems + 1, // +1 for Top Banner
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: AppConstants.spacingMd),
                    child: SmartBanner(position: AdPosition.top),
                  );
                }
                final postIndex = index - 1;

                // Si es el último item y hay más, mostrar botón de cargar más
                if (postIndex == newsResponse.posts.length) {
                  return _buildLoadMoreButton(postIndex);
                }

                return Column(
                  children: [
                    NewsCard(
                      post: newsResponse.posts[postIndex],
                      tvId: 'news_card_$postIndex',
                      tvUpId: postIndex == 0
                          ? 'news_search'
                          : 'news_card_${postIndex - 1}',
                      tvDownId: postIndex < (totalItems - 1)
                          ? 'news_card_${postIndex + 1}'
                          : (newsResponse.hasMore
                              ? 'news_loadmore'
                              : 'mini_banner'),
                      tvLeftId: 'nav_2',
                    ),
                    // In-Feed Ads Injection
                    if (postIndex == 2 || postIndex == 7)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: AppConstants.spacingMd),
                        child: SmartBanner(position: AdPosition.in_feed),
                      ),
                  ],
                );
              },
            ),
          );
        },
        loading: () => const NewsListSkeleton(itemCount: 5),
        error: (error, stackTrace) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.article_outlined,
            size: AppConstants.iconSizeXl * 2,
            color: Colors.grey,
          ),
          const SizedBox(height: AppConstants.spacingLg),
          Text(
            'No hay noticias disponibles',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
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
              'Error al cargar noticias',
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
            TVButton(
              id: 'news_retry',
              leftId: 'nav_2',
              onPressed: () {
                ref.invalidate(newsListProvider(_currentPage));
              },
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('Reintentar'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton(int lastIndex) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.spacingMd),
      child: Center(
        child: TVButton(
          id: 'news_loadmore',
          upId: 'news_card_${lastIndex - 1}',
          downId: 'mini_banner', // Conectar al MiniPlayer
          leftId: 'nav_2',
          onPressed: () {
            setState(() {
              _currentPage++;
            });
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_downward),
              SizedBox(width: 8),
              Text('Cargar más noticias'),
            ],
          ),
        ),
      ),
    );
  }
}
