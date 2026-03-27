# Screen: OnboardingScreen

## 1. Purpose
The `OnboardingScreen` provides a high-fidelity visual walkthrough to introduce new gym owners to the primary benefits of IronBook GM. It handles the initial first-run state management to ensure a smooth transition to the `SignupScreen`.

## 2. Architecture & Modules
- **Location**: `lib/features/auth/onboarding/onboarding_screen.dart`
- **State Management**: ConsumerStatefulWidget, leveraging a local `PageController`.
- **Completion Provider**: `authProvider` (Tracks the global application state).

## 3. Workflow & Functionality
1. **Slide Visualization**: Uses a scrollable `PageView` containing themed slides:
    - **Slide 1: IronBook GM**: General efficiency intro.
    - **Slide 2: Smart Tracking**: Highlights membership monitoring.
    - **Slide 3: Sales POS**: Showcases the integrated supplement store feature.
2. **Smooth Transitions**: Animated transitions between steps with a dot indicator.
3. **Completion Path**: Upon hitting "Get Started", it calls `ref.read(authProvider.notifier).completeOnboarding()`.
4. **Navigation**: Redirects the user to `/signup` to begin account initialization.

## 4. Connections & Interactions
- **Connected to `AuthCache`**: Once completed, a persistent `onboarding_done` flag is set to `true` in secure storage or shared preferences.
- **Boot Flow Integration**: The `AppRouter` checks this flag on startup (via `ref.watch(authProvider)`) to decide between showing `OnboardingScreen` or `SplashScreen`.

## 5. Logic Safeguards (Hardenings Committed)
- **Harden 1 (Fixed)**: Resolved `use_build_context_synchronously` lint errors by caching a local `GoRouter` instance before asynchronous completion calls.
- **Harden 2 (Fixed)**: Replaced deprecated `.withOpacity()` usage with modern `.withValues(alpha: ...)` for visual components.
- **Harden 3 (Fixed)**: Ensured "Get Started" is disabled during the completion transition to prevent double-navigation.

## 6. Dependencies
- `authProvider` (State Engine)
- `AppColors` & `AppTheme` (Visual Language)
- `go_router` (Navigation Route)
- `StatusBarWrapper` (Viewport Consistency)
