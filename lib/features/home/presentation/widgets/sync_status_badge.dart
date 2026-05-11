import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/data/sync_worker.dart';
import '../../../../core/providers/bootstrap_provider.dart';

class SyncStatusBadge extends ConsumerWidget {
  const SyncStatusBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unsyncedCountProvider).valueOrNull ?? 0;
    final status = ref.watch(tier2StatusProvider);
    final syncState = ref.watch(syncWorkerStatusProvider);
    
    if (count == 0 &&
        status != Tier2Status.degraded &&
        syncState.status == SyncWorkerStatus.idle) {
      if (syncState.lastSuccessAt == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'LAST SECURED: ${syncState.lastSuccessAt!.hour}:${syncState.lastSuccessAt!.minute.toString().padLeft(2, "0")}',
          style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 6, letterSpacing: 0.5, color: AppColors.textMuted),
        ),
      );
    }

    final isSyncing = syncState.status == SyncWorkerStatus.syncing || count > 0;
    final isFailed = syncState.status == SyncWorkerStatus.failed;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          duration: const Duration(seconds: 1),
          tween: Tween(begin: 0.5, end: 1.0),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Opacity(
              opacity: isSyncing ? value : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFailed
                      ? AppColors.expired.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isFailed
                        ? AppColors.expired.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isFailed
                          ? Icons.sync_problem_rounded
                          : (isSyncing
                              ? Icons.cloud_sync_rounded
                              : Icons.cloud_done_rounded),
                      size: 10,
                      color: isFailed ? AppColors.expired : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isFailed
                          ? 'SYNC ERROR'
                          : (isSyncing
                              ? '$count ITEM(S) SECURING'
                              : 'DATA SECURED'),
                      style: AppTextStyles.sectionTitle.copyWith(
                        fontSize: 7,
                        letterSpacing: 0.5,
                        color: isFailed ? AppColors.expired : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (syncState.lastSuccessAt != null && !isSyncing)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '${syncState.lastSuccessAt!.hour}:${syncState.lastSuccessAt!.minute.toString().padLeft(2, "0")}',
              style: AppTextStyles.sectionTitle
                  .copyWith(fontSize: 6, color: AppColors.textMuted),
            ),
          ),
      ],
    );
  }
}
