import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/news_provider.dart';
import '../widgets/news_card.dart';
import '../widgets/news_card_skeleton.dart';
import '../../../core/widgets/tv_focusable_widgets.dart';
import '../../../core/services/platform_service.dart';

/// SearchDelegate para buscar noticias
class NewsSearchDelegate extends SearchDelegate<String> {
  NewsSearchDelegate(this.ref);

  final WidgetRef ref;

  @override
  String get searchFieldLabel => 'Buscar noticias...';

  @override
  List<Widget> buildActions(BuildContext context) {
    final isTv = ref.watch(isTvProvider);

    if (query.isEmpty) return [];

    // En TV, usar TVIconButton
    if (isTv) {
      return [
        TVIconButton(
          id: 'search_clear',
          leftId: 'search_back',
          downId: 'search_result_0',
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          showSuggestions(context);
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    final isTv = ref.watch(isTvProvider);

    // En TV, usar TVIconButton
    if (isTv) {
      return TVIconButton(
        id: 'search_back',
        rightId: query.isNotEmpty ? 'search_clear' : 'search_result_0',
        downId: 'search_result_0',
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );
    }

    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().isEmpty) {
      return const Center(child: Text('Escribe algo para buscar'));
    }

    final searchAsync = ref.watch(newsSearchProvider(query.trim()));
    final isTv = ref.watch(isTvProvider);

    return searchAsync.when(
      data: (newsResponse) {
        if (newsResponse.posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron resultados para "$query"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: newsResponse.posts.length,
          itemBuilder: (context, index) {
            return NewsCard(
              post: newsResponse.posts[index],
              // Pasar TV IDs solo en modo TV
              tvId: isTv ? 'search_result_$index' : null,
              tvUpId: isTv
                  ? (index == 0 ? 'search_back' : 'search_result_${index - 1}')
                  : null,
              tvDownId: isTv
                  ? (index < newsResponse.posts.length - 1
                      ? 'search_result_${index + 1}'
                      : null)
                  : null,
              tvLeftId: isTv ? 'search_back' : null,
            );
          },
        );
      },
      loading: () => const NewsListSkeleton(itemCount: 3),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Error al buscar',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Busca noticias por título o contenido',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // Mientras escribe, mostrar el mismo resultado
    return buildResults(context);
  }
}
