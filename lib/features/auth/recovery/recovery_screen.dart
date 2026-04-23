import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/sync/recovery_service.dart';

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
  String? _error;

  @override
  void initState() {
    super.initState();
    // Schedule the start after the first frame to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRecovery();
    });
  }

  Future<void> _startRecovery() async {
    try {
      final recoveryService = ref.read(recoveryServiceProvider);
      
      await recoveryService.recoverAll(
        onProgress: (done, total) {
          if (mounted) {
            setState(() {
              _done = done;
              _total = total;
              _progress = done / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isComplete = true;
          _progress = 1.0;
        });
        
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) context.go('/setup-pin');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
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
                Icon(
                  _error != null ? Icons.error_outline_rounded : Icons.cloud_download_outlined,
                  size: 80, 
                  color: _error != null ? AppColors.expired : AppColors.primary
                ),
                const SizedBox(height: 32),
                Text(
                  _error != null ? 'Recovery Failed' : 'Restoring Data',
                  style: AppTextStyles.cardTitle.copyWith(fontSize: 24)
                ),
                const SizedBox(height: 12),
                Text(
                  _error ?? 'Please wait while we sync your records from the cloud.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                ),
                const SizedBox(height: 48),
                if (_error == null) ...[
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
                  Text(
                    _total > 0 ? 'Restoring $_done / $_total events' : 'Initializing...',
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                        _progress = 0;
                        _done = 0;
                        _total = 0;
                      });
                      _startRecovery();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Try Again'),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Cancel'),
                  ),
                ],
                if (_isComplete) ...[
                  const SizedBox(height: 24),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.active, size: 32),
                      SizedBox(width: 8),
                      Text('Verification Successful', style: TextStyle(color: AppColors.active, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
