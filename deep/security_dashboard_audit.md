# Audit: Security & Dashboard

## PIN Authentication (`pin_setup_screen.dart` & `pin_entry_screen.dart`)
### PinSetupScreen:
- **Flow**: Enter PIN -> Confirm PIN -> (If Match) -> Save to `secure_storage` -> Show Fingerprint Opt-in.
- **Loose End**: If the user kills the app during the Fingerprint Opt-In screen, `completeOnboarding()` has already been called. The next launch will treat them as a "Returning User".

### PinEntryScreen (CRITICAL ISSUE):
- **Current Logic**: 
  ```dart
  if (_pin.length == 4) {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) context.go('/dashboard');
    });
  }
  ```
- **Finding**: **NO VALIDATION**. The UI simply navigates to the dashboard as soon as 4 digits are entered, regardless of what those digits are. This is a massive security flaw. It *should* call `ref.read(authProvider.notifier).verifyPin(_pin)`.

---

## Dashboard (`lib/features/home/presentation/screens/dashboard_screen.dart`)
### Functionality:
- **Hub**: Primary screen for gym management.
- **Data Layers**:
    - `membersProvider`: Provides the list of member snapshots.
    - `authProvider`: Provides the owner profile.
- **Logic**: Calculates active/expiring/expired counts on-the-fly in the `build` method.
### Audit Findings:
- **Performance**: Recalculating member statuses in `build` every time is fine for <100 members, but will lag with 500+. This should be memoized or moved to a provider.
- **Placeholders**: `onRefresh` is not implemented. Revenue chart is static.
- **Navigation**: The `AppBottomNavBar` transition logic is duplicated in the screen instead of being handled by a shell route in `GoRouter`. This causes the bottom bar to re-animate/re-build on every navigation.
