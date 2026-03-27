# Screen: SplashScreen

## 1. Purpose
The `SplashScreen` is the entry point of the application. It serves dual purposes: establishing the premium brand identity and orchestrating the initial application state routing. 

## 2. Architecture & Modules
- **Location**: `lib/features/auth/splash/splash_screen.dart`
- **State Management**: ConsumerStatefulWidget (Riverpod).
- **Orchestrator**: `authProvider` (Determines the next navigation destination).

## 3. Workflow & Functionality
1. **Visual Phase**: Displays the high-fidelity IronBook GM brand logo with a smooth "fade-in" and "scale-up" animation.
2. **Boot Logic Phase**: On widget mount, it initiates the `ref.read(authProvider.notifier)` initialization logic.
3. **Routing Decision**: After a brief brand awareness delay (800ms to 2.5s), it performs a 3-way routing check:
    - **A (New User)**: Redirects to `/onboarding` if the `onboarding_done` flag is absent.
    - **B (Returning Owner)**: Redirects to `/pin-entry` if a session exists and PIN security is active.
    - **C (Unauthenticated)**: Redirects to `/login` if no local identity is found.
4. **Error Resilience**: If the local database is corrupted or fails to load, it falls back to a "Recovery Mode" prompt.

## 4. Connections & Interactions
- **Root Entry Point**: The destination for the native OS splash screen hand-off.
- **Provider Influence**: The `authProvider` state (`uninitialized`, `authenticated`, `unauthenticated`) directly dictates the final routing path.

## 5. Logic Safeguards (Hardenings Committed)
- **Harden 1 (Fixed)**: Replaced deprecated `.withOpacity()` usage with modern `.withValues(alpha: ...)` for the background gradient.
- **Harden 2 (Fixed)**: Implemented a `SafeContext` check to prevent routing attempts if the user closes the app during the boot animation (fixed potential memory leak).
- **Harden 3 (Fixed)**: Integrated with `StatusBarWrapper` to ensure a bezel-to-bezel immersive brand experience.

## 6. Dependencies
- `authProvider` (Routing Logic)
- `AppColors` & `AppTheme` (Visual Branding)
- `go_router` (Redirection Core)
- `StatusBarWrapper` (Display consistency)
