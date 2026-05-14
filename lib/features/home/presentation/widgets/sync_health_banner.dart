import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/data/sync_worker.dart';

class SyncHealthBanner extends ConsumerWidget {
  const SyncHealthBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(syncHealthProvider);

    return healthAsync.when(
      data: (isHealthy) {
        if (isHealthy) return const SizedBox.shrink();
        
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.m),
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: AppColors.red.withOpacity(0.1),
            borderRadius: AppRadius.radiusL,
            border: Border.all(color: AppColors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.red, size: 20),
              AppSpacing.gapM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SYNC DELAYED',
                      style: AppTextStyles.sectionTitle.copyWith(color: AppColors.red),
                    ),
                    Text(
                      'Local data hasn\'t synced with cloud for over 7 days. Please check your connection.',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
