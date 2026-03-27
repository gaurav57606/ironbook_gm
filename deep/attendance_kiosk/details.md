# Screen: KioskScreen (Attendance)

## 1. Purpose
The `KioskScreen` is a dedicated interface designed for member self-service. It allows members to check in independently via a 4-digit PIN, reducing front-desk friction and automating attendance tracking.

## 2. Architecture & Modules
- **Location**: `lib/features/attendance/presentation/screens/kiosk_screen.dart`
- **State Management**: ConsumerStatefulWidget, leveraging `membersProvider` for real-time verification.
- **Verification Engine**: Locally cross-references input against the `MemberSnapshot` repository.

## 3. Workflow & Functionality
1. **Identification Phase**: Members enter a 4-digit PIN. The system attempts to match this against:
    - **`checkInPin`**: A unique PIN assigned to the member.
    - **Last 4 Digits of Phone**: A fallback for members who forget their custom PIN.
2. **Status Validation**: Upon finding a matching record, the system verifies `member.getStatus()`.
    - **Active**: Triggers an attendance log event and shows a themed "Welcome" success UI.
    - **Expired**: Rejects the check-in and displays a "Plan Expired" warning.
3. **Timed Reset**: Automatically resets back to the `idle` state after 3-4 seconds to clear the screen for the next member.

## 4. Connections & Interactions
- **Connected to `MemberSnapshot`**: Pulls the `name` and `status` for personalized feedback.
- **Integrated with `membersProvider`**: Rebuilds/reacts to changes in the member database (e.g., if a member is added while the kiosk is open).
- **Secondary Actions**: A close button (`X`) allows the owner to exit the kiosk mode back to the dashboard (requires owner re-authentication in production).

## 5. Logic Safeguards (Hardenings Committed)
- **Harden 1 (Fixed)**: Replaced the "1234" dummy PIN with real-time Hive member lookup.
- **Harden 2 (Fixed)**: Implemented `MemberStatus.expired` blocking logic directly into the kiosk flow.
- **Harden 3 (Fixed)**: UI visual indicators (circles) now use `withValues(alpha: ...)` to comply with the latest Flutter standards.

## 6. Dependencies
- `membersProvider` (Real-time Repository)
- `StatusBarWrapper` (Viewport Consistency)
- `AppColors` (Thematic Branding)
- `go_router` (Navigation Control)
