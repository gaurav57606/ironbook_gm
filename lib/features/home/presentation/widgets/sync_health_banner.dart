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
    final statusAsync = ref.watch(syncHealthStatusProvider);

    // Listen for critical status to show a blocking dialog
    ref.listen(syncHealthStatusProvider, (previous, next) {
      next.whenData((status) {
        if (status == SyncHealthStatus.critical) {
          _showCriticalSyncDialog(context, ref);
        }
      });
    }, fireImmediately: true);

    return statusAsync.when(
      data: (status) {
        if (status == SyncHealthStatus.healthy) return const SizedBox.shrink();
        
        final isCritical = status == SyncHealthStatus.critical;
        final color = isCritical ? AppColors.red : AppColors.amber;
        final title = status == SyncHealthStatus.neverSynced 
            ? 'NOT YET SYNCED' 
            : (isCritical ? 'SYNC REQUIRED' : 'SYNC OVERDUE');
        
        final message = status == SyncHealthStatus.neverSynced
            ? 'Your data is only stored locally. Connect to internet to sync.'
            : (isCritical 
                ? 'Sync hasn\'t happened in over 7 days. Critical sync required.' 
                : 'Sync is overdue — please connect to internet to secure your data.');

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.m),
          padding: const EdgeInsets.all(AppSpacing.m),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: AppRadius.radiusL,
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                status == SyncHealthStatus.neverSynced ? Icons.cloud_queue_rounded : Icons.cloud_off_rounded, 
                color: color, 
                size: 20
              ),
              AppSpacing.gapM,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.sectionTitle.copyWith(color: color),
                    ),
                    Text(
                      message,
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (isCritical)
                IconButton(
                  onPressed: () => _showCriticalSyncDialog(context, ref),
                  icon: const Icon(Icons.info_outline_rounded, color: AppColors.red),
                ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  void _showCriticalSyncDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false, // Blocking
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bg2,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.red),
            AppSpacing.gapM,
            const Text('Sync Required', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Your local data has not been synced with the cloud for over 7 days. '
          'To prevent data loss and ensure system integrity, a successful sync is required before you can continue.\n\n'
          'Please connect to the internet and try syncing now.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(syncWorkerProvider).performSync();
              Navigator.pop(context);
            },
            child: const Text('SYNC NOW', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
