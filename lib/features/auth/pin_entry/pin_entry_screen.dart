import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../providers/auth_provider.dart';

class PinEntryScreen extends ConsumerStatefulWidget {
  const PinEntryScreen({super.key});

  @override
  ConsumerState<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends ConsumerState<PinEntryScreen> {
  String _pin = '';

  void _onDigitPress(String digit) {
    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
      });
      if (_pin.length == 6) {
        _verifyPin();
      }
    }
  }

  Future<void> _verifyPin() async {
    final success = await ref.read(authProvider.notifier).verifyPin(_pin);
    if (!mounted) return;
    if (success) {
      context.go('/');
    } else {
      setState(() => _pin = '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid PIN')),
      );
    }
  }

  Future<void> _handleBiometric() async {
    final success = await ref.read(authProvider.notifier).loginWithBiometrics();
    if (success && mounted) {
      context.go('/');
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const Icon(Icons.lock_outline, size: 48, color: AppColors.primary),
            const SizedBox(height: 24),
            Text('Enter PIN', style: AppTextStyles.cardTitle.copyWith(fontSize: 24)),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                6,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  height: 16,
                  width: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _pin.length ? AppColors.primary : AppColors.bg4,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/login'),
              child: Text('Forgot PIN?', style: AppTextStyles.label.copyWith(color: AppColors.primary)),
            ),
            const Spacer(),
            _buildKeypad(),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        children: [
          _buildRow(['1', '2', '3']),
          _buildRow(['4', '5', '6']),
          _buildRow(['7', '8', '9']),
          _buildRow([const Icon(Icons.fingerprint, color: AppColors.primary), '0', 'delete']),
        ],
      ),
    );
  }

  Widget _buildRow(List<dynamic> items) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((item) {
        if (item is Icon) {
          return InkWell(
            onTap: _handleBiometric,
            borderRadius: BorderRadius.circular(40),
            child: Container(width: 80, height: 80, alignment: Alignment.center, child: item),
          );
        }
        return InkWell(
          onTap: () => item == 'delete' ? _onDelete() : _onDigitPress(item),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            child: item == 'delete'
                ? const Icon(Icons.backspace_outlined, color: AppColors.textPrimary)
                : Text(item, style: AppTextStyles.heroNumber.copyWith(fontSize: 28, color: AppColors.textPrimary)),
          ),
        );
      }).toList(),
    );
  }
}
