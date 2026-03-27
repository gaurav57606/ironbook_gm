# Screen: MemberDetailScreen

## 1. Purpose
The `MemberDetailScreen` provides a high-fidelity dashboard for individual member management. It tracks subscription status, payment history, and biometric alignment.

## 2. Architecture & Modules
- **Location**: `lib/features/members/presentation/screens/member_detail_screen.dart`
- **State Management**: ConsumerStatefulWidget, using Riverpod and local state for event history.
- **Provider Access**: `membersProvider` (Primary state), `eventRepositoryProvider` (Audit history).

## 3. Workflow & Functionality
1. **Dynamic Loading**: Watches the `membersProvider` to always display the latest reactive snapshot of the member.
2. **Audit History**: Fetches a specific event timeline for the `memberId` from the `eventRepository`. This provides a non-repudiable log of all membership changes.
3. **Status Indicators**: Uses `MemberSnapshot.getStatus()` to determine UI themes (Active = Green, Expiring = Amber, Expired = Red).
4. **Quick Actions**: 
    - **Generate Invoice**: Links to the billing module.
    - **Renew**: Future integration point for membership extensions.
    - **WhatsApp**: Intent-based communication using member phone metadata.

## 4. Connections & Interactions
- **Upstream**: `MembersListScreen` (Navigation source).
- **Downstream**: `InvoiceScreen` (Action target).
- **Data Source**: Rebuilds instantly whenever a new `DomainEvent` affecting this member is persisted to Hive.

## 5. Logic Safeguards
- **Loading State**: Displays a branded spinner if the selected member snapshot is not yet hydrated from disk.
- **Null Safety**: Gracefully handles missing phone numbers or expiry dates.
- **Locked Edits**: Join dates are "locked" in the UI to prevent accidental tampering, emphasizing the integrity of the audit log.

## 6. Dependencies
- `membersProvider` (Main Snapshot)
- `eventRepositoryProvider` (History Source)
- `DateFormatter` & `CurrencyFormatter` (Localization)
- `AppButton` (Interaction)
- `go_router` (Navigation)
