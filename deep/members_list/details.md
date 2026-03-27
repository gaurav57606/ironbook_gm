# Screen: MembersListScreen

## 1. Purpose
The `MembersListScreen` serves as the primary directory for gym owners to manage their member base. It provides efficient search, status-based filtering, and access to detailed profiles.

## 2. Architecture & Modules
- **Location**: `lib/features/members/presentation/screens/members_list_screen.dart`
- **State Management**: ConsumerWidget using Riverpod for list state and local `StateProvider` for search/filter terms.
- **Data Model**: `MemberSnapshot` collection.

## 3. Workflow & Functionality
1. **Initial State**: Pulls sorted `snapshots` from the `membersProvider`.
2. **Dynamic Search**: Filters members in real-time by `name` or `phone` (Case-insensitive).
3. **Status Filtration**: Uses a tab-based UI to filter for:
    - **All**: Entire gym roster.
    - **Active**: Current paid-up members.
    - **Expiring**: Members whose plans expire in <= 7 days.
    - **Expired**: Members whose plans have ended.
4. **Member Navigation**: Tapping a member card triggers `context.push('/member/XYZ')`.

## 4. Connections & Interactions
- **Connected to `MemberDetailScreen`**: Displays detailed membership history and biometrics.
- **Connected to `QuickAddMemberScreen`**: Provides an "Add Member" shortcut in the top AppBar.
- **Logic Sync**: All filter states are persistent for the current app session.

## 5. Logic Safeguards
- **Empty State**: If no members match the filters, a themed "No results found" placeholder is displayed to avoid a blank screen.
- **Status Computation**: Relies on a shared logic in `MemberSnapshot.getStatus()` to ensure status consistency across all screens.
- **Optimized Rendering**: Uses `ListView.separated` for efficient rendering of large member lists (1-1000+).

## 6. Dependencies
- `membersProvider` (Snapshot Registry)
- `AppColors` (Thematic Consistency)
- `MemberCard` (Reusable UI Fragment)
- `AppTextField` (Search Bar)
- `lucide_icons` (System Aesthetics)
