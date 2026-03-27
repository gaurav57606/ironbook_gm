import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_bar_wrapper.dart';
import '../../../../providers/auth_provider.dart';

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
  final TextEditingController _confirmPasswordController = TextEditingController();
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
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await ref.read(authProvider.notifier).signUp(
      _emailController.text,
      _passwordController.text,
      gymName: _gymNameController.text,
      ownerName: _ownerNameController.text,
      phone: _phoneController.text,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        context.go('/pin-setup');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signup failed. Email might already be in use.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StatusBarWrapper(
      child: SingleChildScrollView(
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
                child: const Icon(Icons.chevron_left, size: 18, color: AppColors.text),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Set up your gym',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Create your account to get started',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Gym Name',
              hint: 'Raj\'s Fitness',
              controller: _gymNameController,
            ),
            AppTextField(
              label: 'Your Name',
              hint: 'Rajesh Kumar',
              controller: _ownerNameController,
            ),
            AppTextField(
              label: 'Email Address',
              hint: 'raj@rajsfitness.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            AppTextField(
              label: 'Phone',
              hint: '+91 98765 43210',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            AppTextField(
              label: 'Password',
              hint: '••••••••',
              controller: _passwordController,
              isPassword: true,
            ),
            AppTextField(
              label: 'Confirm Password',
              hint: '••••••••',
              controller: _confirmPasswordController,
              isPassword: true,
            ),
            const SizedBox(height: 8),
            AppButton(
              text: _isLoading ? 'Creating Account...' : 'Create Account',
              onPressed: _isLoading ? null : _handleSignup,
            ),
            const SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: () => context.go('/login'),
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 10, color: AppColors.text2, fontFamily: 'Outfit'),
                    children: [
                      TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Log in',
                        style: TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
