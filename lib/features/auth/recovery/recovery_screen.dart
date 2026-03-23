import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  double _progress = 0.0;
  int _done = 0;
  int _total = 0;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _startRecovery();
  }

  Future<void> _startRecovery() async {
    // In a real implementation, this would call FirestoreRecovery.restoreAll
    // and update state via the onProgress callback.
    // For now, simulating progress.
    _total = 100;
    for (int i = 0; i <= _total; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) {
        setState(() {
          _done = i;
          _progress = i / _total;
          if (i == _total) _isComplete = true;
        });
      }
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go('/pin-setup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: PopScope(
        canPop: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_download_outlined,
                    size: 80, color: AppColors.primary),
                const SizedBox(height: 32),
                Text('Restoring Data',
                    style: AppTextStyles.cardTitle.copyWith(fontSize: 24)),
                const SizedBox(height: 12),
                Text('Please wait while we sync your records from the cloud.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 48),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    backgroundColor: AppColors.bg4,
                    color: AppColors.primary,
                    minHeight: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Text('Restoring $_done / $_total events',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                if (_isComplete) ...[
                  const SizedBox(height: 24),
                  const Icon(Icons.check_circle, color: AppColors.active, size: 32),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
