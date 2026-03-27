# Architecture: Data Storage & Sync Pipeline

This document explains how IronBook GM handles data persistence, synchronization, and daily status updates.

## 1. Local Storage Stack
The app uses **Hive**, a lightweight and blazing-fast NoSQL database, for all local storage.
- **`events` box**: The "Single Source of Truth." Stores every mutation (add, edit, renew) as a Domain Event.
- **`snapshots` box**: Read-optimized cache. Stores the final state of each member.
- **`plans` & `settings` boxes**: Store gym configuration and subscription plans.

## 2. The Data Flow Pipeline (Write Path)
When you perform an action (e.g., adding a member):
1. **Event Creation**: The app creates a `DomainEvent` (UUID-indexed).
2. **Security**: The event is signed using **HMAC** to prevent tampering.
3. **Persistence (WAL)**: The event is saved to the local `events` box immediately.
4. **Snapshot Rebuilding**: A background listener watches for new events, applies them to the current member data via the `SnapshotBuilder`, and updates the `snapshots` box.
5. **UI Reactivity**: Since the `membersProvider` watches the `snapshots` box, the screen updates instantly.

## 3. Background Synchronization (Cloud Sync)
- **`SyncWorker`**: A background service that periodically pulls "unsynced" events from the local database and pushes them to **Firestore**.
- **Idempotency**: We use the `eventId` as the Firestore Document ID. If a sync attempt is interrupted and retried, it simply overwrites the same document, preventing duplicate records.

## 4. Update on "Day Change" (Midnight Engine)
How does the app know when a membership expires while the app is closed?
- **`MidnightEngine`**: Uses Flutter's `Workmanager` to schedule a task that runs every 24 hours.
- **Status Recalculation**: At midnight, it wakes up, iterates through all members, and calls `snapshot.getStatus(DateTime.now())`.
- **Alerts**: If a member has moved into "Expiring" or "Expired" status, it sends a system notification via the `NotificationService`.

## 5. Fetching Data Locally
- **Reactive Reads**: All UI screens use **Riverpod Providers** (e.g., `membersProvider`).
- **Speed**: Providers read directly from the Hive `snapshots` memory-cached box. This ensures zero-latency page transitions and 100% offline functionality.
- **Search & Filter**: Searching is performed locally using standard Dart collection methods (`where`, `contains`) on the snapshotted list.
