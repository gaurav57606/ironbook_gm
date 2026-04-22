import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/sync_status_provider.dart';

class LeaseExpiredScreen extends ConsumerWidget {
  const LeaseExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusProvider);
    final unsyncedCount = syncStatus.unsyncedCount;

    return StatusBarWrapper(
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.expired.withValues(alpha: 0.1),
                AppColors.bg,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.expired.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.vpn_key_off_rounded,
                  size: 64,
                  color: AppColors.expired,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'LEASE EXPIRED',
                style: AppTextStyles.h1.copyWith(
                  color: AppColors.expired,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Your 7-day offline lease has expired. To continue using IronBook GM, you must synchronize your local data with the secure cloud.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: AppColors.text3),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('UNSYNCED DATA', style: TextStyle(color: AppColors.text3, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.bold)),
                        Text('$unsyncedCount ITEMS', style: const TextStyle(color: AppColors.expired, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: AppColors.bg,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.expired),
                      minHeight: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // This will trigger the sync worker naturally if online
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Re-establishing cloud connection...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.expired,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('SYNC NOW TO RENEW LEASE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  // Logout to re-establish auth if needed
                },
                child: Text(
                  'CONTACT SUPPORT',
                  style: AppTextStyles.label.copyWith(color: AppColors.text3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
