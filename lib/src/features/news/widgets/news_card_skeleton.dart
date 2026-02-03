import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_constants.dart';

/// Skeleton loader para NewsCard
///
/// Muestra un placeholder animado mientras se cargan las noticias
class NewsCardSkeleton extends StatelessWidget {
  const NewsCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingMd),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Skeleton de imagen
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMd),
                ),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // Skeleton de título (2 líneas)
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXs),
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Container(
                height: 20,
                width: double.infinity * 0.6,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXs),
                ),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // Skeleton de extracto (3 líneas)
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXs),
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Container(
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXs),
                ),
              ),
              const SizedBox(height: AppConstants.spacingSm),
              Container(
                height: 14,
                width: double.infinity * 0.7,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.radiusXs),
                ),
              ),

              const SizedBox(height: AppConstants.spacingMd),

              // Skeleton de metadata (fecha y categorías)
              Row(
                children: [
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusXs,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacingMd),
                  Container(
                    height: 12,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusXs,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Lista de skeleton loaders para múltiples cards
class NewsListSkeleton extends StatelessWidget {
  const NewsListSkeleton({super.key, this.itemCount = 3});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
      itemCount: itemCount,
      itemBuilder: (context, index) => const NewsCardSkeleton(),
    );
  }
}
