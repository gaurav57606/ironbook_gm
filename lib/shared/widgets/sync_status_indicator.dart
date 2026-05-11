import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ironbook_gm/core/providers/bootstrap_provider.dart';
import 'package:ironbook_gm/core/data/sync_worker.dart';
import 'package:ironbook_gm/core/constants/app_colors.dart';
import 'package:ironbook_gm/core/constants/app_radius.dart';
import 'package:ironbook_gm/core/constants/app_text_styles.dart';

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(tier2StatusProvider);
    final unsyncedCount = ref.watch(unsyncedCountProvider).asData?.value ?? 0;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _buildIndicator(context, status, unsyncedCount),
    );
  }

  Widget _buildIndicator(BuildContext context, Tier2Status status, int unsynced) {
    if (status == Tier2Status.pending) {
      return const _Pill(
        key: ValueKey('pending'),
        label: 'CONNECTING',
        icon: Icons.sync_rounded,
        color: AppColors.primary,
        isAnimated: true,
      );
    }

    if (status == Tier2Status.degraded) {
      return const _Pill(
        key: ValueKey('degraded'),
        label: 'OFFLINE',
        icon: Icons.cloud_off_rounded,
        color: AppColors.expired,
      );
    }

    if (unsynced > 0) {
      return _Pill(
        key: const ValueKey('syncing'),
        label: 'SYNCING $unsynced',
        icon: Icons.cloud_upload_rounded,
        color: AppColors.primary,
        isAnimated: true,
      );
    }

    return const _Pill(
      key: ValueKey('synced'),
      label: 'SECURE',
      icon: Icons.verified_user_rounded,
      color: AppColors.active,
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isAnimated;

  const _Pill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.isAnimated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.radiusM,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color)
              .animate(
                autoPlay: !const bool.fromEnvironment('FLUTTER_TEST'),
                onPlay: (controller) => (isAnimated && !const bool.fromEnvironment('FLUTTER_TEST')) ? controller.repeat() : null,
              )
              .rotate(duration: 2.seconds),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}









