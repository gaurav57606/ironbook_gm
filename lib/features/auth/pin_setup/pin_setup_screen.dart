import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';

  void _onDigitPress(String digit) {
    if (_pin.length < 6) {
      setState(() {
        _pin += digit;
      });
      if (_pin.length == 6) {
        // In a real app, verify and save PIN.
        context.go('/');
      }
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
            Text('Set Your PIN', style: AppTextStyles.cardTitle.copyWith(fontSize: 24)),
            const SizedBox(height: 12),
            Text('Create a 6-digit PIN for quick access to your data.',
                style: AppTextStyles.bodySmall),
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
          _buildRow([null, '0', 'delete']),
        ],
      ),
    );
  }

  Widget _buildRow(List<String?> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: digits.map((d) {
        if (d == null) return const SizedBox(width: 80, height: 80);
        return InkWell(
          onTap: () => d == 'delete' ? _onDelete() : _onDigitPress(d),
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            child: d == 'delete'
                ? const Icon(Icons.backspace_outlined, color: AppColors.textPrimary)
                : Text(d, style: AppTextStyles.heroNumber.copyWith(fontSize: 28, color: AppColors.textPrimary)),
          ),
        );
      }).toList(),
    );
  }
}
