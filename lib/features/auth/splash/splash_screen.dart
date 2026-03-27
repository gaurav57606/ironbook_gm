import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for a minimum time for branding
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authState = ref.read(authProvider);

    // Logic: 
    // 1. First time? -> Onboarding
    // 2. Logged in? 
    //    a. PIN Setup? -> Pin Entry (if locked)
    //    b. PIN not setup? -> Pin Setup
    // 3. Not logged in? -> Login
    if (authState.isFirstLaunch) {
      context.go('/onboarding');
    } else if (authState.isAuthenticated) {
      if (authState.isPinSetup) {
        if (authState.unlocked) {
          context.go('/dashboard');
        } else {
          context.go('/pin-entry');
        }
      } else {
        context.go('/pin-setup');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Box
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                children: const [
                  TextSpan(text: 'IronBook '),
                  TextSpan(
                    text: 'GM',
                    style: TextStyle(color: AppColors.orange),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Gym Management · Solo Owner Edition',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: AppColors.text2,
              ),
            ),
            const SizedBox(height: 32),
            // Loading Spinner
            Column(
              children: [
                RotationTransition(
                  turns: _controller,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.orange,
                        width: 2,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -2,
                          left: -2,
                          right: -2,
                          bottom: -2,
                          child: CustomPaint(
                            painter: SpinnerPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading...',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: AppColors.text3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SpinnerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color =
          AppColors.bg // Matches background to "cut out" part of the border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Drawing an arc to simulate the "border-top-color: transparent"
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -math.pi / 2,
      math.pi / 2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
