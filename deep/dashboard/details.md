# Screen: DashboardScreen

## 1. Purpose
The `DashboardScreen` is the "Mission Control" for the gym owner. It provides a real-time, high-level overview of gym health, financial performance, and immediate urgent actions (e.g., expiring memberships).

## 2. Architecture & Modules
- **Location**: `lib/features/dashboard/presentation/screens/dashboard_screen.dart`
- **State Management**: ConsumerWidget (Riverpod).
- **Aggregator Logic**: Uses `ref.watch(membersProvider)` to compute derived metrics in real-time.

## 3. Workflow & Functionality
1. **Metrics Engine**:
    - **Total Members**: Count of all records in the `snapshots` box.
    - **Active Members**: Computed via `member.getStatus() == MemberStatus.active`.
    - **Revenue Today**: Aggregated from the `paymentProvider` for the current calendar day.
    - **Expiring Soon**: Count of members with <= 7 days remaining.
2. **Activity Feed**: Shows the most recent 5-10 `DomainEvents` (Member joined, Receipt shared).
3. **Synchronicity Awareness**: Displays a subtle "Syncing..." indicator using `ref.watch(syncStatusProvider)` to show background cloud uploads.
4. **Primary Navigation**: Acts as the root of the `AppBottomNavBar` persistent layout.

## 4. Connections & Interactions
- **Connected to `MembersListScreen`**: Quick shortcut to "View All Members".
- **Connected to `QuickAddMemberScreen`**: Central "Quick Add" FAB (Floating Action Button).
- **Security Check**: Periodically verifies session validity via `authProvider`.

## 5. Logic Safeguards
- **Zero-Latency UI**: All stats are computed from the local Hive memory cache. No network calls block the dashboard render.
- **Graceful Error Recovery**: If the `membersProvider` is empty, it displays a "Welcome & Setup" guide instead of empty charts.
- **Refresh Control**: Supporting "Pull-to-Refresh" manually triggers a `SyncWorker` pass.

## 6. Dependencies
- `membersProvider` (Data Aggregation)
- `paymentProvider` (Financial Summary)
- `syncStatusProvider` (Connectivity Feedback)
- `AppBottomNavBar` (Navigation Structure)
- `StatCard` & `ActivityRow` (UI Fragments)
- `go_router` (Navigation Routing)
