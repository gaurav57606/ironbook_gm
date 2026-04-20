import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../security/entitlement_guard.dart';

class LicenseSyncScreen extends ConsumerStatefulWidget {
  const LicenseSyncScreen({super.key});

  @override
  ConsumerState<LicenseSyncScreen> createState() => _LicenseSyncScreenState();
}

class _LicenseSyncScreenState extends ConsumerState<LicenseSyncScreen> {
  bool _isChecking = false;
  String? _error;

  Future<void> _handleRetry() async {
    setState(() {
      _isChecking = true;
      _error = null;
    });

    // Invalidate the entitlement provider to force a fresh cloud check
    ref.invalidate(entitlementStatusProvider);
    final status = await ref.read(entitlementStatusProvider.future);

    if (mounted) {
      setState(() {
        _isChecking = false;
        if (status == EntitlementStatus.expired) {
          _error = 'Your license could not be verified. Please contact support or check your internet connection.';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                  Icons.sync_problem_rounded,
                  size: 80,
                  color: AppColors.expired,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                'License Sync Required',
                style: AppTextStyles.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'To maintain gym sequence security and rental compliance, a cloud check is required every 7 days. Your last check-in has expired.',
                style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text(
                    _error!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.expired),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isChecking ? null : _handleRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isChecking
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CHECK LICENSE NOW'),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: Text(
                  'Sign Out',
                  style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
