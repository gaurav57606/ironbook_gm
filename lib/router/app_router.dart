import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Splash & Onboarding
import '../features/auth/splash/splash_screen.dart';
import '../features/auth/onboarding/onboarding_screen.dart';

// New Feature Screens
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/pin_setup_screen.dart';
import '../features/auth/presentation/screens/pin_entry_screen.dart';
import '../features/auth/presentation/screens/lease_expired_screen.dart';
import '../features/home/presentation/screens/dashboard_screen.dart';
import '../features/members/presentation/screens/members_list_screen.dart';
import '../features/members/presentation/screens/member_detail_screen.dart';
import '../features/members/presentation/screens/quick_add_member_screen.dart';
import '../features/billing/presentation/screens/pos_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import '../features/settings/presentation/screens/profile_screen.dart';
import '../features/settings/presentation/screens/security_settings_screen.dart';
import '../features/settings/presentation/screens/notifications_settings_screen.dart';
import '../features/settings/presentation/screens/gym_profile_screen.dart';
import '../features/settings/presentation/screens/subscription_screen.dart';
import '../features/settings/presentation/screens/tax_billing_screen.dart';
import '../features/settings/presentation/screens/help_center_screen.dart';
import '../features/settings/presentation/screens/about_screen.dart';
import '../features/settings/presentation/screens/plan_management_screen.dart';
import '../features/settings/presentation/screens/profile_edit_screen.dart';
import '../features/auth/recovery/recovery_screen.dart';
import '../features/settings/presentation/screens/ownership_transfer_screen.dart';
import '../features/home/presentation/widgets/main_shell.dart';
import '../features/backup/presentation/backup_restore_screen.dart';

// Newly Added Screens
import '../features/analytics/presentation/screens/analytics_screen.dart';
import '../features/nutrition/presentation/screens/nutrition_screen.dart';
import '../features/notifications/presentation/screens/notifications_hub_screen.dart';
import '../features/character_creation/presentation/screens/character_creation_screen.dart';

import '../providers/auth_provider.dart';
import '../providers/bootstrap_provider.dart';
import '../security/entitlement_guard.dart';

final routerProvider = Provider.family<GoRouter, bool>((ref, hiveHealthy) {
  final authState = ref.watch(authProvider);
  final tier2Status = ref.watch(tier2StatusProvider);
  final bootstrap = ref.watch(bootstrapStateProvider);
  final entitlementStatus = ref.watch(entitlementStatusProvider);

  return GoRouter(
    initialLocation: '/',
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
    redirect: (context, state) {
      // 0. Hard Block until Phase 1 (Core) is done
      if (bootstrap == BootstrapPhase.tier1Pending) return null;

      // 1. Splash Screen Holding Pattern (Stay until Tier 2 is determined)
      final isSplash = state.matchedLocation == '/';
      if (tier2Status == Tier2Status.pending && isSplash) return null;

      // 2. Auth Loading Guard
      if (authState.isLoading) return null;

      final isAuth = authState.isAuthenticated;
      final onboardingDone = !authState.isFirstLaunch;
      final isPinSetup = authState.isPinSetup;
      final unlocked = authState.unlocked;

      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup' ||
          state.matchedLocation == '/forgot-password';
      final isOnboarding = state.matchedLocation == '/onboarding';
      final isPinSetupPath = state.matchedLocation == '/setup-pin';
      final isPinEntryPath = state.matchedLocation == '/unlock';

      // 3. Onboarding Redirect
      if (!onboardingDone) {
         if (isOnboarding) return null;
         return '/onboarding';
      }

      // 4. Tier 2 Guard for Protected Routes
      // We allow Login/Onboarding screens after Tier 1 Ready.
      // But we BLOCK dashboard/gym access until Tier 2 (Firebase Auth) is determined (Ready/Degraded).
      final isProtectedRoute = !isLoggingIn && !isOnboarding && !isSplash;
      
      if (isProtectedRoute && tier2Status == Tier2Status.pending) {
        return '/'; // Hold on Splash
      }

      // 5. Auth Redirect
      if (!isAuth) {
         if (isLoggingIn || isOnboarding) return null;
         return '/login';
      }

      // 6. Post-Auth Routing (PIN & Landing)
      if (isSplash || isLoggingIn || isOnboarding) {
         if (isPinSetup && !unlocked) return '/unlock';
         if (!isPinSetup) return '/setup-pin';
         return '/dashboard';
      }

      // 7. PIN Enforcement
      if (isPinSetup && !unlocked && !isPinEntryPath) {
        return '/unlock';
      }

      if (!isPinSetup && !isPinSetupPath && !state.matchedLocation.startsWith('/settings')) {
        return '/setup-pin';
      }

      // 8. Entitlement Guard (Paywall)
      final isSettings = state.matchedLocation.startsWith('/settings');
      if (isAuth && !isSettings && state.matchedLocation != '/paywall') {
        final status = entitlementStatus.valueOrNull ?? EntitlementStatus.valid;
        if (status == EntitlementStatus.expired) {
          return '/lease-expired';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/setup-pin',
        builder: (context, state) => const PinSetupScreen(),
      ),
      GoRoute(
        path: '/unlock',
        builder: (context, state) => const PinEntryScreen(),
      ),
      GoRoute(
        path: '/recovery',
        builder: (context, state) => const RecoveryScreen(),
      ),
      GoRoute(
        path: '/character-creation',
        builder: (context, state) => const CharacterCreationScreen(),
      ),
      GoRoute(
        path: '/lease-expired',
        builder: (context, state) => const LeaseExpiredScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/gym',
                builder: (context, state) => const MembersListScreen(),
                routes: [
                  GoRoute(
                    path: 'add-member',
                    builder: (context, state) => const QuickAddMemberScreen(),
                  ),
                  GoRoute(
                    path: 'member-details/:id',
                    builder: (context, state) => MemberDetailScreen(
                      memberId: state.pathParameters['id']!,
                    ),
                  ),
                  GoRoute(
                    path: 'member-edit/:id',
                    builder: (context, state) => MemberDetailScreen(
                      memberId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/nutrition',
                builder: (context, state) => const NutritionScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/pos',
                builder: (context, state) => const PosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/analytics',
                builder: (context, state) => const AnalyticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'profile',
                    builder: (context, state) => const ProfileScreen(),
                  ),
                  GoRoute(
                    path: 'profile/owner',
                    builder: (context, state) => const ProfileEditScreen(isGymProfile: false),
                  ),
                  GoRoute(
                    path: 'profile/gym',
                    builder: (context, state) => const ProfileEditScreen(isGymProfile: true),
                  ),
                  GoRoute(
                    path: 'security',
                    builder: (context, state) => const SecuritySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) => const NotificationsSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'gym-profile',
                    builder: (context, state) => const GymProfileScreen(),
                  ),
                  GoRoute(
                    path: 'plans',
                    builder: (context, state) => const PlanManagementScreen(),
                  ),
                  GoRoute(
                    path: 'subscription',
                    builder: (context, state) => const SubscriptionScreen(),
                  ),
                  GoRoute(
                    path: 'tax-billing',
                    builder: (context, state) => const TaxBillingScreen(),
                  ),
                  GoRoute(
                    path: 'help',
                    builder: (context, state) => const HelpCenterScreen(),
                  ),
                  GoRoute(
                    path: 'about',
                    builder: (context, state) => const AboutScreen(),
                  ),
                  GoRoute(
                    path: 'transfer',
                    builder: (context, state) => const OwnershipTransferScreen(),
                  ),
                  GoRoute(
                    path: 'backup',
                    builder: (context, state) => const BackupRestoreScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallPlaceholder(),
      ),
    ],
  );
});

class PaywallPlaceholder extends StatelessWidget {
  const PaywallPlaceholder({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Paywall')));
}
