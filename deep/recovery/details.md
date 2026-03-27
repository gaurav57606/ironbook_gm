# Screen: RecoveryScreen

## Purpose
Disaster recovery for local database from Firestore events.

## Components
- Linear progress indicator showing event processing.
- Status counter (e.g., "100/100 events restored").

## Logic
- Sequentially processes encrypted domain events to rebuild the local state after data loss or app re-install.

## Dependencies
- `EventRepository`
- `SyncEngine`
