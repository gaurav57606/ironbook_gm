# Screen: SignupScreen

## 1. Purpose
The `SignupScreen` facilitates the initial registration of a new gym owner (merchant). It captures core identity data and initiates the owner's encrypted digital infrastructure.

## 2. Architecture & Modules
- **Location**: `lib/features/auth/signup/signup_screen.dart`
- **State Management**: ConsumerStatefulWidget (Riverpod).
- **Backend Infrastructure**: `firebase_auth` (Account creation) and `Firestore` (Profile metadata).

## 3. Workflow & Functionality
1. **Merchant Profile**: Captures `Owner Name`, `Gym Name`, and `Phone`.
2. **Account Linking**: Connects the provided profile with the active Firebase User ID from `GoogleSignIn`.
3. **Registration Logic**:
    - **Step 1**: Validates non-empty presence for all merchant fields.
    - **Step 2**: Persists the Merchant Metadata to Firestore (`owners` collection).
    - **Step 3**: Initializes the local Hive `settings` box with the new `Gym Name`.
    - **Step 4**: Triggers a navigation path to `/pin-setup` for security isolation.
4. **Transition State**: Displays a branded loading state while the Firestore handshake is performed.

## 4. Connections & Interactions
- **Connected to `PinSetupScreen`**: The mandatory next step in the owner’s digital setup.
- **Provider Influence**: On completion, the `authProvider` transition to `requiresPinSetup` state.

## 5. Logic Safeguards (Hardenings Committed)
- **Harden 1 (Fixed)**: Implemented `StatusBarWrapper` to ensure visual layout consistency across Android/iOS.
- **Harden 2 (Fixed)**: Replaced deprecated `.withOpacity()` usage with modern `.withValues(alpha: ...)` for the UI background layers.
- **Harden 3 (Fixed)**: Ensured that existing merchants are automatically merged instead of duplicated if they attempt to sign up twice with the same ID.

## 6. Dependencies
- `authProvider` (Identity Orchestrator)
- `Firestore` (Global Metadata)
- `AppButton` & `AppTextField` (UI components)
- `go_router` (Navigation Routing)
- `AppColors` & `StatusBarWrapper` (Display consistency)
