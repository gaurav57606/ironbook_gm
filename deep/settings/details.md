# Screen: SettingsScreen

## 1. Purpose
The `SettingsScreen` serves as the configuration engine and data management hub for the IronBook GM application. It allows gym owners to customize billing parameters, manage their cloud sync identity, and perform maintenance tasks.

## 2. Architecture & Modules
- **Location**: `lib/features/settings/presentation/screens/settings_screen.dart`
- **State Management**: ConsumerWidget (Riverpod).
- **Configuration Engine**: `AppSettingsProvider` (Persistent Hive storage for toggles and keys).

## 3. Workflow & Functionality
1. **Gym Configuration**:
    - **Branding**: Set gym name and logo for use in invoices.
    - **Plans**: Create and edit membership tiers (Daily, Monthly, Quarterly, Yearly).
2. **Data & Cloud Management**:
    - **Cloud Sync Status**: Manual trigger for the `SyncWorker` and a visual representation of the last successful backup.
    - **Database Integrity**: Tool to verify HMAC signatures of local `DomainEvents`.
    - **Recovery Tools**: Full backup and restore capabilities using the `RecoveryService`.
3. **Security Context**: Allows enabling/disabling Biometric Authentication and PIN requirements.
4. **Audit Mode Persistence**: Includes the `auditMode` toggle which affects how authentication is handled throughout the app session.

## 4. Connections & Interactions
- **Connected to `AppRouter`**: Redirects to `PinSetupScreen` if a new PIN is requested.
- **Data Source**: Real-time reactive updates from `AppSettings`.
- **Side-Effects**: Configuration changes immediately affect systemic visual and logic behaviors.

## 5. Logic Safeguards (Hardenings Committed)
- **Harden 1 (Fixed)**: Purged all "Mock Seeding" and "Simulate Load" buttons that were used during development to prevent accidental production data corruption.
- **Harden 2 (Fixed)**: Cleaned up lint warnings related to unused imports and deprecated `Material` properties.
- **Harden 3 (Fixed)**: Ensured `About` section displays the consistent version number from `pubspec.yaml` via a dynamic builder.

## 6. Dependencies
- `AppSettingsProvider` (Main Persistence)
- `authProvider` (Session Controls)
- `SyncWorker` (Maintenance Tasks)
- `RecoveryService` (Backup/Restore Logic)
- `AppColors` & `StatusBarWrapper` (UI Aesthetics)
- `go_router` (Navigation Routing)
