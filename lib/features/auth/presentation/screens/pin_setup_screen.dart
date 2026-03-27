import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/auth_provider.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  bool _confirming = false;
  String _confirmedPin = '';
  bool _showBiometric = false;
  bool _error = false;
  bool _isLoading = false;

  void _onKeyPress(String key) {
    if (_isLoading) return;
    setState(() {
      _error = false;
      if (key == '⌫') {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else if (_pin.length < 4) {
        _pin += key;
        if (_pin.length == 4) {
          _handlePinComplete();
        }
      }
    });
  }

  Future<void> _handlePinComplete() async {
    if (!_confirming) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _confirming = true;
          _confirmedPin = _pin;
          _pin = '';
        });
      }
    } else {
      if (_pin == _confirmedPin) {
        setState(() => _isLoading = true);
        await ref.read(authProvider.notifier).setPin(_confirmedPin);
        await ref.read(authProvider.notifier).completeOnboarding();
        
        if (mounted) {
          setState(() {
            _isLoading = false;
            _showBiometric = true;
          });
        }
      } else {
        setState(() {
          _error = true;
          _pin = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showBiometric) {
      return StatusBarWrapper(
        showHeader: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.fingerprint, color: AppColors.orange, size: 32),
              ),
              const SizedBox(height: 14),
              const Text(
                'Enable fingerprint unlock?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Skip the PIN and open the app with your fingerprint.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.text2,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Enable Fingerprint',
                onPressed: () async {
                  await ref.read(authProvider.notifier).setBiometricOptIn(true);
                  if (!context.mounted) return;
                  context.go('/dashboard');
                },
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => context.go('/dashboard'),
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.text3,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return StatusBarWrapper(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 14),
            child: Column(
              children: [
                Text(
                  _confirming ? 'Confirm your PIN' : 'Create your PIN',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _confirming
                      ? 'Enter the same PIN again to confirm'
                      : 'You\'ll use this PIN every time you open the app',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.text2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final isFilled = index < _pin.length;
              return Container(
                width: 14,
                height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppColors.orange : Colors.transparent,
                  border: Border.all(
                    color: _error ? AppColors.red : (isFilled ? AppColors.orange : AppColors.border),
                    width: 1.5,
                  ),
                ),
              );
            }),
          ),
          if (_error) ...[
            const SizedBox(height: 16),
            const Text(
              'PINs don\'t match, try again',
              style: TextStyle(fontSize: 10, color: AppColors.red),
            ),
          ],
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const CircularProgressIndicator(color: AppColors.orange),
          ],
          const Spacer(),
          Padding(
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
                const SizedBox(),
                _buildKey('0'),
                _buildKey('⌫'),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
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
}
