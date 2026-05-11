import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../../shared/widgets/app_text_field.dart';
import '../../../../core/providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _gymNameController = TextEditingController();
  final TextEditingController _ownerNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _gymNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_gymNameController.text.isEmpty ||
        _ownerNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.expired,
        ),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.expired,
        ),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: AppColors.expired,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).signUp(
          _emailController.text.trim(),
          _passwordController.text,
          gymName: _gymNameController.text.trim(),
          ownerName: _ownerNameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/setup-pin');
      } else {
        final authState = ref.read(authProvider);
        final isCritical = authState.authAttempts >= 3;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isCritical 
              ? 'Multiple failed attempts. Is the email correct? Try Recovery if you already have an account.' 
              : 'Signup failed. Email might already be in use.'),
            backgroundColor: AppColors.expired,
            duration: Duration(seconds: isCritical ? 5 : 3),
            action: isCritical ? SnackBarAction(
              label: 'RECOVERY',
              textColor: Colors.white,
              onPressed: () => context.push('/recovery'),
            ) : null,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('signup-root'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          top: true,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackButton(context),
                      const SizedBox(height: 32),
                      _buildHeader(),
                      const SizedBox(height: 32),
                      _buildSignupForm(context),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.pop(),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.elevation1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.chevron_left_rounded,
            size: 24, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Account',
          style: AppTextStyles.h1.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 8),
        Text(
          'Set up your gym profile to get started',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm(BuildContext context) {
    return Column(
      children: [
        AppTextField(
          key: const Key('input-signup-gym'),
          label: 'Gym Name',
          hint: 'Raj\'s Fitness',
          controller: _gymNameController,
        ),
        AppTextField(
          key: const Key('input-signup-owner'),
          label: 'Your Name',
          hint: 'Rajesh Kumar',
          controller: _ownerNameController,
        ),
        AppTextField(
          key: const Key('input-signup-email'),
          label: 'Email Address',
          hint: 'raj@rajsfitness.com',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        AppTextField(
          key: const Key('input-signup-phone'),
          label: 'Phone',
          hint: '+91 98765 43210',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        AppTextField(
          key: const Key('input-signup-password'),
          label: 'Password',
          hint: '••••••••',
          controller: _passwordController,
          isPassword: true,
        ),
        AppTextField(
          key: const Key('input-signup-confirm'),
          label: 'Confirm Password',
          hint: '••••••••',
          controller: _confirmPasswordController,
          isPassword: true,
        ),
        const SizedBox(height: 16),
        AppButton(
          key: const Key('btn-signup'),
          text: _isLoading ? 'Creating Account...' : 'Create Account',
          onPressed: _isLoading ? null : _handleSignup,
        ),
        const SizedBox(height: 24),
        Center(
          child: GestureDetector(
            onTap: () => context.go('/login'),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                children: const [
                  TextSpan(text: 'Already have an account? '),
                  TextSpan(
                    text: 'Log in',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}









