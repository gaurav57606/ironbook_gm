import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).login(
          _emailController.text,
          _passwordController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/dashboard');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login failed. Please check your credentials.'),
            backgroundColor: AppColors.expired,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      showHeader: false,
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(),
                  const SizedBox(height: 32),
                  _buildHeader(),
                  const SizedBox(height: 48),
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildFooter(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'IG',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: -1,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: AppTextStyles.h1.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 8),
        Text(
          'Log in to your gym account',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        AppTextField(
          label: 'Email Address',
          hint: 'raj@rajsfitness.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 8),
        AppTextField(
          label: 'Password',
          hint: '••••••••',
          controller: _passwordController,
          isPassword: true,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.push('/forgot-password'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              'Forgot password?',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        AppButton(
          text: _isLoading ? 'Logging In...' : 'Log In',
          onPressed: _isLoading ? null : _handleLogin,
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return GestureDetector(
      onTap: () => context.go('/signup'),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          children: const [
            TextSpan(text: "New here? "),
            TextSpan(
              text: "Create an account",
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
