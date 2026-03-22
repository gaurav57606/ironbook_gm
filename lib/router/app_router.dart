import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/splash/splash_screen.dart';
import '../features/auth/onboarding/onboarding_screen.dart';
import '../features/auth/login/login_screen.dart';
import '../features/auth/signup/signup_screen.dart';
import '../features/auth/forgot_password/forgot_password_screen.dart';
import '../features/auth/pin_setup/pin_setup_screen.dart';
import '../features/auth/pin_entry/pin_entry_screen.dart';
import '../features/auth/recovery/recovery_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/members/list/members_screen.dart';
import '../features/members/detail/member_detail_screen.dart';
import '../features/members/invoice/invoice_screen.dart';
import '../features/quick_add/quick_add_screen.dart';
import '../features/settings/settings_screen.dart';
import '../providers/auth_provider.dart';
import '../security/entitlement_guard.dart';

final routerProvider = Provider.family<GoRouter, bool>((ref, hiveHealthy) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(path: '/signup', builder: (c, s) => const SignupScreen()),
      GoRoute(path: '/login', builder: (c, s) => const LoginScreen()),
      GoRoute(path: '/forgot-password', builder: (c, s) => const ForgotPasswordScreen()),
      GoRoute(path: '/recovery', builder: (c, s) => const RecoveryScreen()),
      GoRoute(path: '/pin-setup', builder: (c, s) => const PinSetupScreen()),
      GoRoute(path: '/pin-entry', builder: (c, s) => const PinEntryScreen()),
      GoRoute(path: '/paywall', builder: (c, s) => const Scaffold(body: Center(child: Text('Paywall')))), // Placeholder

      ShellRoute(
        builder: (context, state, child) => Scaffold(
          body: child,
          bottomNavigationBar: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Members'),
              BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
            ],
            onTap: (index) {
              if (index == 0) context.go('/');
              if (index == 1) context.go('/members');
              if (index == 2) context.go('/settings');
            },
          ),
        ),
        routes: [
          GoRoute(path: '/', builder: (c, s) => DashboardScreen()),
          GoRoute(path: '/members', builder: (c, s) => const MembersScreen()),
          GoRoute(path: '/members/:id', builder: (c, s) => MemberDetailScreen(id: s.pathParameters['id']!)),
          GoRoute(path: '/members/:id/invoice', builder: (c, s) => InvoiceScreen(id: s.pathParameters['id']!)),
          GoRoute(path: '/add', builder: (c, s) => const QuickAddScreen()),
          GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
        ],
      )
    ],
    redirect: (context, state) async {
      // 1. Hive Health Guard
      if (!hiveHealthy && state.matchedLocation != '/recovery') return '/recovery';

      // 2. Entitlement Guard
      final ent = await EntitlementGuard.checkEntitlement();
      if (ent == EntitlementStatus.expired && state.matchedLocation != '/paywall') return '/paywall';

      // 3. Auth Guard
      final user = FirebaseAuth.instance.currentUser;
      final isAuthRoute = state.matchedLocation == '/login' || 
                         state.matchedLocation == '/signup' || 
                         state.matchedLocation == '/forgot-password' ||
                         state.matchedLocation == '/onboarding' ||
                         state.matchedLocation == '/splash';
      
      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      // 4. PIN Setup Guard
      if (!authState.isPinSetup && state.matchedLocation != '/pin-setup') return '/pin-setup';

      // 5. PIN Entry Guard
      if (!authState.unlocked && state.matchedLocation != '/pin-entry' && state.matchedLocation != '/pin-setup') return '/pin-entry';

      // If authenticated and unlocked, don't stay on auth routes
      if (isAuthRoute || state.matchedLocation == '/pin-entry' || state.matchedLocation == '/pin-setup' || state.matchedLocation == '/recovery') {
        return '/';
      }

      return null;
    },
  );
});
