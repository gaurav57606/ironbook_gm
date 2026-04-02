import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/auth_provider.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  final bool isLockout;
  const PinEntryScreen({super.key, this.isLockout = false});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  String _pin = '';
  bool _error = false;
  bool _isLoading = false;
  int _attempts = 0;

  void _onKeyPress(String key) {
    if (widget.isLockout || _isLoading) return;
    setState(() {
      _error = false;
      if (key == '⌫') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else if (_pin.length < 4) {
        _pin += key;
        if (_pin.length == 4) {
          _handleVerify();
        }
      }
    });
  }

  Future<void> _handleVerify() async {
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).verifyPin(_pin);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/dashboard');
      } else {
        setState(() {
          _error = true;
          _attempts++;
          _pin = '';
        });
        if (_attempts >= 3) {
          // Implement lockout logic if needed
        }
      }
    }
  }

  Future<void> _handleBiometric() async {
    final success = await ref.read(authProvider.notifier).unlockWithBiometrics();
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
              child: Column(
                children: [
                  const Text('Raj\'s Fitness', style: TextStyle(fontSize: 11, color: AppColors.text2)),
                  const SizedBox(height: 10),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.center,
                    child: const Text('R', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                  const SizedBox(height: 12),
                  const Text('Enter your PIN', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
                  if (_error)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Incorrect PIN. Please try again.', style: TextStyle(fontSize: 10, color: AppColors.red)),
                    ),
                  if (widget.isLockout)
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Text('Incorrect PIN. Try again in 27s...', style: TextStyle(fontSize: 10, color: AppColors.red)),
                    ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                final Color color = (widget.isLockout || _error) ? AppColors.red : AppColors.orange;
                return Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (widget.isLockout) ? color.withValues(alpha: 0.2) : (isFilled ? color : Colors.transparent),
                    border: Border.all(color: color, width: 1.5),
                  ),
                );
              }),
            ),
            const SizedBox(height: 40), // Replaced Spacer
            Opacity(
              opacity: widget.isLockout ? 0.35 : 1.0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1.2,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    ...['1', '2', '3', '4', '5', '6', '7', '8', '9'].map((k) => _buildKey(k)),
                    _buildSpecialKey(Icons.fingerprint, _handleBiometric, isBiometric: true),
                    _buildKey('0'),
                    _buildKey('⌫'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => context.push('/forgot-password'),
              child: const Text('Forgot PIN?', style: TextStyle(fontSize: 10, color: AppColors.orange)),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String key) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(key),
        borderRadius: BorderRadius.circular(40),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bg3.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            key,
            style: TextStyle(
              fontSize: key == '⌫' ? 14 : 18,
              fontWeight: FontWeight.w600,
              color: AppColors.text,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(IconData icon, VoidCallback onTap, {bool isBiometric = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(40),
        child: Container(
          decoration: BoxDecoration(
            color: isBiometric ? Colors.transparent : AppColors.bg3.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            border: Border.all(color: isBiometric ? Colors.transparent : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.orange, size: 24),
        ),
      ),
    );
  }
}
