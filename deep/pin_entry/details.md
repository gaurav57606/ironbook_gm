# Screen: PinEntryScreen

## 1. Purpose
The `PinEntryScreen` serves as a secure re-authentication gateway for established app sessions. It protects the gym's sensitive financial and member data from unauthorized access if the device is left unattended.

## 2. Architecture & Modules
- **Location**: `lib/features/auth/presentation/screens/pin_entry_screen.dart`
- **State Management**: ConsumerStatefulWidget, leveraging Riverpod for secure credentials.
- **Provider Access**: `authProvider` (Verification Engine).

## 3. Workflow & Functionality
1. **PIN Input**: Provides a high-fidelity numeric keypad for inputting a 4-digit security PIN.
2. **Persistence Comparison**: Upon entering the 4th digit, it calls `ref.read(authProvider.notifier).verifyPin(...)`. This method compares the salted/hashed input against the local secure storage.
3. **Biometric Bypass**: Includes an optional fingerprint/face ID trigger using `local_auth` integration, allowing for faster entry when enabled.
4. **Lockout Logic**: Tracks failed attempts and implements a time-based lockout (integrated with the `isLockout` parameter) to prevent brute-force attacks.

## 4. Connections & Interactions
- **Upstream**: Reached during app resume or manually via the "Lock" button in the dashboard.
- **Downstream**: Success leads back to the `DashboardScreen`.
- **Security Context**: Operates in "Audit Mode Awareness", ensuring that even in audit sessions, real security policies are respected.

## 5. Logic Safeguards (Hardenings Committed)
- **Harden 1 (Fixed)**: Removed the diagnostic bypass that allowed any 4 digits to pass. Now requires a exact match.
- **Harden 2 (Fixed)**: UI visual indicators (circles) now respond to error states with distinct thematic Red (`AppColors.red`) feedback.
- **Harden 3 (Fixed)**: Implemented `StatusBarWrapper` to ensure the screen occupies the full viewport without system UI overlap.

## 6. Dependencies
- `authProvider` (Verification Core)
- `AppColors` (Visual Language)
- `local_auth` (Biometric Integration)
- `go_router` (Navigation Gate)
