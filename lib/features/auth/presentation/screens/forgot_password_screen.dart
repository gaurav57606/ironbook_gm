import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../../shared/widgets/status_bar_wrapper.dart';
import '../../../../core/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _emailSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .sendPasswordReset(_emailController.text);
      if (mounted) {
        setState(() => _emailSent = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_emailSent) {
      return _buildSuccessView(context);
    }

    return _buildResetView(context);
  }

  Widget _buildSuccessView(BuildContext context) {
    return StatusBarWrapper(
      showHeader: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: AppColors.green, size: 24),
            ),
            const SizedBox(height: 10),
            const Text(
              'Email sent!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check ${_emailController.text} for your reset link. Check your spam folder too.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.text2,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 20),
            AppButton(
              text: 'Back to Login',
              onPressed: () => context.go('/login'),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isLoading ? null : _handleReset,
              child: Text(
                _isLoading ? 'Sending...' : 'Resend email',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetView(BuildContext context) {
    return StatusBarWrapper(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.bg3,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(Icons.chevron_left,
                    size: 18, color: AppColors.text),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Reset password',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Enter your email and we\'ll send a reset link.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Email Address',
              hint: 'raj@rajsfitness.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            AppButton(
              text: _isLoading ? 'Sending Reset Link...' : 'Send Reset Link',
              onPressed: _isLoading ? null : _handleReset,
            ),
          ],
        ),
      ),
    );
  }
}









