# Audit: Splash & Onboarding

## SplashScreen (`lib/features/auth/splash/splash_screen.dart`)
### Functionality:
- **Branding**: Displays the IronBook GM logo and title with a custom rotation animation.
- **Initialisation**: Wait for 2 seconds (`Future.delayed`) to ensure branding visibility and allow `AuthNotifier` to initialize its internal Hive/SecureStorage state.
- **Navigation Logic**:
    - Reads `authState.isAuthenticated`.
    - If `true` -> `/dashboard`.
    - If `false` -> `/login`.
### Loose Ends / Potential Issues:
- The logic is extremely rigid. If the app is in an intermediate state (e.g., Auth is valid but PIN is NOT setup), it relies on the `/dashboard` redirect in `GoRouter` to bounce the user to `/pin-setup`. This might cause a "flash" of the dashboard.

---

## OnboardingScreen (`lib/features/auth/onboarding/onboarding_screen.dart`)
### Functionality:
- **UI**: 3-page `PageView` explaining core features (Tracking, Invoices, Flexibility).
- **Controls**: `Next`/`Get started` button and a `Skip` option.
- **Completion**: Calls `completeOnboarding()` on `authProvider.notifier`.
### Audit Findings:
- **Touch Responsiveness**: The "Get started" button uses a `GestureDetector` on a `Container`. If unresponsive, it's likely due to the `await completeOnboarding()` call hanging.
- **Logic Safeguard**: If `completeOnboarding()` fails (e.g., Hive disk error), the user is stuck. There is no `try-catch` around the `await` call.
- **Assets**: Relies on `assets/images/onb_1.png` etc. If these are missing, the UI might show a placeholder or error depending on Flutter version.
