import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/splash/splash_screen.dart';
import '../../features/auth/onboarding/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/pin_setup_screen.dart';
import '../../features/auth/presentation/screens/pin_entry_screen.dart';
import '../../features/auth/recovery/recovery_screen.dart';
import '../../features/auth/presentation/screens/lease_expired_screen.dart';
import '../../features/home/presentation/screens/dashboard_screen.dart';
import '../../features/home/presentation/widgets/main_shell.dart';
import '../../features/members/presentation/screens/members_list_screen.dart';
import '../../features/members/presentation/screens/quick_add_member_screen.dart';
import '../../features/members/presentation/screens/member_detail_screen.dart';
import '../../features/billing/presentation/screens/invoice_screen.dart';
import '../../features/billing/presentation/screens/pos_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/profile_edit_screen.dart';
import '../../features/settings/presentation/screens/security_settings_screen.dart';
import '../../features/settings/presentation/screens/notifications_settings_screen.dart';
import '../../features/settings/presentation/screens/gym_profile_screen.dart';
import '../../features/settings/presentation/screens/plan_management_screen.dart';
import '../../features/settings/presentation/screens/subscription_screen.dart';
import '../../features/settings/presentation/screens/tax_billing_screen.dart';
import '../../features/settings/presentation/screens/help_center_screen.dart';
import '../../features/settings/presentation/screens/about_screen.dart';
import '../../features/settings/presentation/screens/ownership_transfer_screen.dart';
import '../../features/backup/presentation/backup_restore_screen.dart';

// Newly Added Screens
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/notifications/presentation/screens/notifications_hub_screen.dart';
import '../../features/legal/presentation/screens/legal_screens.dart';

import 'package:ironbook_gm/core/providers/auth_provider.dart';
import 'package:ironbook_gm/core/providers/bootstrap_provider.dart';
import 'package:ironbook_gm/core/security/entitlement_guard.dart';

final routerProvider = Provider.family<GoRouter, bool>((ref, storageHealthy) {
  final refreshListenable = ValueNotifier<int>(0);
  ref.onDispose(() => refreshListenable.dispose());
  ref.listen(authProvider.select((s) => s.isAuthenticated), (_, __) => refreshListenable.value++);
  ref.listen(authProvider.select((s) => s.isFirstLaunch), (_, __) => refreshListenable.value++);
  ref.listen(authProvider.select((s) => s.isLoading), (_, __) => refreshListenable.value++);
  ref.listen(authProvider.select((s) => s.isPinSetup), (_, __) => refreshListenable.value++);
  ref.listen(authProvider.select((s) => s.unlocked), (_, __) => refreshListenable.value++);
  ref.listen(tier2StatusProvider, (_, __) => refreshListenable.value++);
  ref.listen(bootstrapStateProvider, (_, __) => refreshListenable.value++);
  ref.listen(entitlementStatusProvider, (_, __) => refreshListenable.value++);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshListenable,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.toString()}'),
      ),
    ),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final tier2Status = ref.read(tier2StatusProvider);
      final bootstrap = ref.read(bootstrapStateProvider);
      final entitlementStatus = ref.read(entitlementStatusProvider);

      final path = state.matchedLocation;

      // 1. Bootstrap gating
      if (bootstrap == BootstrapPhase.tier1Pending) return null;
      
      // 2. Fatal startup gating (Splash holding)
      if (tier2Status == Tier2Status.pending && path == '/') return null;

      // 3. Auth loading (Stay on splash while loading)
      // Hydrated Startup: We no longer block on isRecovering.
      if (authState.isLoading) return null;

      final isAuth = authState.isAuthenticated;
      final isFirstLaunch = authState.isFirstLaunch;
      final isPinSetup = authState.isPinSetup;
      final unlocked = authState.unlocked;

      final isLoginPath = path == '/login' || path == '/signup' || path == '/forgot-password';
      final isOnboardingPath = path == '/onboarding';
      final isUnlockPath = path == '/unlock';
      final isPinSetupPath = path == '/setup-pin';
      final isLeasePath = path == '/lease-expired';
      final isSettingsPath = path.startsWith('/settings');

      // 4. Onboarding flow (Prioritize over Auth for new installs)
      if (isFirstLaunch) {
        if (isOnboardingPath) return null;
        return '/onboarding';
      }

      // 5. Authentication validation
      // Unauthenticated users always resolve first to prevent unauth feature access
      if (!isAuth) {
        if (isLoginPath) return null;
        return '/login';
      }

      // 5a. Always allow auth screens through, regardless of onboarding state
      if (isLoginPath) return null;

      // PIN ROUTING
      // If authenticated but PIN not configured,
      // force setup flow first.
      if (isAuth && !isPinSetup) {
        if (!isPinSetupPath) {
          return '/setup-pin';
        }
        return null;
      }

      // If PIN exists but app locked,
      // require unlock.
      if (isAuth && isPinSetup && !unlocked) {
        if (!isUnlockPath) {
          return '/unlock';
        }
        return null;
      }

      // 7. Entitlement validation
      // Do NOT evaluate while loading to prevent false redirects immediately after login
      if (!entitlementStatus.isLoading && entitlementStatus.hasValue) {
        if (entitlementStatus.value == EntitlementStatus.expired && !isLeasePath && !isSettingsPath) {
          return '/lease-expired';
        }
      }

      // 8. Landing routing (If on non-feature screens after all gates passed)
      if (path == '/' || isLoginPath || isOnboardingPath || isUnlockPath || isPinSetupPath) {
        return '/dashboard';
      }

      // 9. Feature routing (Allow the requested route)
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
        path: '/invoice',
        builder: (context, state) {
          final memberId = state.uri.queryParameters['memberId'];
          return InvoiceScreen(memberId: memberId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsHubScreen(),
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
                path: '/members',
                builder: (context, state) => const MembersListScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
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
                    routes: [
                      GoRoute(
                        path: 'invoice',
                        builder: (context, state) => InvoiceScreen(
                          memberId: state.pathParameters['id'],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/invoices',
                builder: (context, state) => const PosScreen(),
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
                    builder: (context, state) =>
                        const ProfileEditScreen(isGymProfile: false),
                  ),
                  GoRoute(
                    path: 'profile/gym',
                    builder: (context, state) =>
                        const ProfileEditScreen(isGymProfile: true),
                  ),
                  GoRoute(
                    path: 'security',
                    builder: (context, state) => const SecuritySettingsScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        const NotificationsSettingsScreen(),
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
                    path: 'backup',
                    builder: (context, state) => const BackupRestoreScreen(),
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
                    path: 'privacy',
                    builder: (context, state) => const LegalScreen(
                      title: 'Privacy Policy',
                      content: LegalScreen.privacyPolicyContent,
                    ),
                  ),
                  GoRoute(
                    path: 'terms',
                    builder: (context, state) => const LegalScreen(
                      title: 'Terms of Service',
                      content: LegalScreen.termsOfServiceContent,
                    ),
                  ),
                  GoRoute(
                    path: 'transfer',
                    builder: (context, state) =>
                        const OwnershipTransferScreen(),
                  ),
                ],
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
        ],
      ),
    ],
  );
});
