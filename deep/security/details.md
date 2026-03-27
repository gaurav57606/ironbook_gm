# Screen: Registration & Security

## 1. Signup Screen (`signup_screen.dart`)
### Purpose:
Captures Owner and Gym details to initialize the workspace.
### Data Points:
- Gym Name, Owner Name, Email, Phone, Password.
### Logic:
- Calls `ref.read(authProvider.notifier).signUp(...)`.
- On success, redirects to `/pin-setup`.
### Redesign Recommendation:
- Add input masks for Phone number.
- Add "Confirm Password" validation in a more visual way (real-time error).

## 2. PIN Setup (`pin_setup_screen.dart`)
### Purpose:
Establish a secondary security layer.
### Workflow:
1. Enter PIN (4 digits).
2. Confirm PIN.
3. Save to Secure Storage.
4. Fingerprint Opt-in.
### Logic:
- Uses `setPin()` in `AuthNotifier`.

## 3. PIN Entry (`pin_entry_screen.dart`)
### Purpose:
Unlock the app on resume or fresh launch.
### CRITICAL FINDING:
- **Major Security Flaw**: The screen currently transitions to `/dashboard` as soon as 4 digits are typed, **WITHOUT** checking if they match the saved PIN.
- **Fix**: Must call `verifyPin(pin)` and only navigate on `true`.
