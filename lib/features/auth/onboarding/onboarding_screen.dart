import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Track every member',
      subtitle: 'See who\'s active, expiring, and due — at a glance every morning.',
    ),
    OnboardingData(
      title: 'Instant invoices',
      subtitle: 'Generate and share professional GST invoices via WhatsApp in seconds.',
    ),
    OnboardingData(
      title: 'Your gym, your rules',
      subtitle: 'Set your own plans, pricing, and components. Everything in one place.',
    ),
  ];

  String _getIllustration() {
    switch (_currentPage) {
      case 0:
        return 'assets/images/onb_1.png';
      case 1:
        return 'assets/images/onb_2.png';
      case 2:
        return 'assets/images/onb_3.png';
      default:
        return 'assets/images/onb_1.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final data = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration
                        Container(
                          width: 360,
                          height: 360,
                          decoration: BoxDecoration(
                            color: AppColors.bg3,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.05),
                                blurRadius: 40,
                                spreadRadius: -10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              _getIllustration(),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Title
                        Text(
                          data.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Subtitle
                        Text(
                          data.subtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 5),
                        height: 5,
                        width: _currentPage == index ? 16 : 5,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.orange : AppColors.text3,
                          borderRadius: BorderRadius.circular(
                            _currentPage == index ? 3 : 50,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Button
                  AppButton(
                    text: _currentPage == _pages.length - 1 ? 'Get started' : 'Next',
                    onPressed: () async {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.ease,
                        );
                      } else {
                        debugPrint('Onboarding: Mark complete and navigating to /signup');
                        final router = GoRouter.of(context);
                        await ref.read(authProvider.notifier).completeOnboarding();
                        if (mounted) {
                          debugPrint('Onboarding: router.go(/signup)');
                          router.go('/signup');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  // Skip Link
                  if (_currentPage < _pages.length - 1)
                    GestureDetector(
                      onTap: () async {
                        final router = GoRouter.of(context);
                        await ref.read(authProvider.notifier).completeOnboarding();
                        if (mounted) router.go('/signup');
                      },
                      child: Text(
                        'Skip',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: AppColors.text3,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 12), // Placeholder to keep layout stable
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;

  OnboardingData({
    required this.title,
    required this.subtitle,
  });
}
