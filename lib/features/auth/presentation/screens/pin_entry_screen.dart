import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import '../../../../core/providers/auth_provider.dart';

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

 
  @override
  void initState() {
    super.initState();
    // Audit Requirement: Biometrics First
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.isLockout) {
        _handleBiometric();
      }
    });
  }

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
    // Use Unified Gateway
    final success = await ref.read(authProvider.notifier).authenticate(pin: _pin);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/dashboard');
      } else {
        setState(() {
          _error = true;
          _pin = '';
        });
      }
    }
  }

  Future<void> _handleBiometric() async {
    // Use Unified Gateway (No PIN means try biometrics)
    final success = await ref.read(authProvider.notifier).authenticate();
    if (success && mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildPinDots(),
                const SizedBox(height: 60),
                _buildNumpad(),
                const SizedBox(height: 32),
                _buildForgotButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      child: Column(
        children: [
          Text(
            'IRONBOOK GM',
            style: AppTextStyles.sectionTitle.copyWith(
              fontSize: 10,
              letterSpacing: 2,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.lock_outline_rounded,
                size: 32, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            'Secure Access',
            style: AppTextStyles.h2.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter your PIN to continue',
            style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
          ),
          if (_error)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Incorrect PIN. Please try again.',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.expired, fontWeight: FontWeight.w700),
              ),
            ),
          if (widget.isLockout)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Incorrect PIN. Try again in 27s...',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.expired, fontWeight: FontWeight.w700),
              ),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 3, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _pin.length;
        final Color color = (widget.isLockout || _error)
            ? AppColors.expired
            : AppColors.primary;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 16,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: color, width: 2),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                    )
                  ]
                : [],
          ),
        );
      }),
    );
  }

  Widget _buildNumpad() {
    return Opacity(
      opacity: widget.isLockout ? 0.35 : 1.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            ...['1', '2', '3', '4', '5', '6', '7', '8', '9']
                .map((k) => _buildKey(k)),
            if (ref.watch(authProvider).settings.useBiometrics)
              _buildSpecialKey(Icons.fingerprint_rounded, _handleBiometric,
                  isBiometric: true)
            else
              const SizedBox.shrink(),
            _buildKey('0'),
            _buildKey('⌫'),
          ],
        ),
      ),
    );
  }

  Widget _buildForgotButton() {
    return TextButton(
      onPressed: () => context.push('/forgot-password'),
      child: Text(
        'Forgot PIN?',
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildKey(String key) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: Key('btn_$key'),
        onTap: () => _onKeyPress(key),
        borderRadius: BorderRadius.circular(50),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.elevation2,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            key,
            style: AppTextStyles.heroNumber.copyWith(
              fontSize: key == '⌫' ? 20 : 24,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialKey(IconData icon, VoidCallback onTap,
      {bool isBiometric = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          decoration: BoxDecoration(
            color: isBiometric ? Colors.transparent : AppColors.elevation2,
            shape: BoxShape.circle,
            border: Border.all(
                color: isBiometric ? Colors.transparent : AppColors.border),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.primary, size: 28),
        ),
      ),
    );
  }
}









