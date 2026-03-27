# IronBook GM: Core Architecture Overview

## 1. Application Lifecycle & Entry Point (`lib/main.dart`)
The application follows a standard Flutter entry point with significant pre-initialization of core services.

### Initialization Sequence:
1.  **System UI**: Status bar set to transparent.
2.  **Firebase**: Initialized for non-web platforms with a 10s timeout.
3.  **Core Services**: FCM, HMAC, and Notification services initialized.
4.  **Hive (Local Data)**: 
    - `Hive.initFlutter()`
    - Manual registration of all TypeAdapters (Events, Snapshots, Payments, Plans, Settings, etc.).
    - `HiveInit.openWithCorruptionGuard()`: Uses a specialized service to open boxes and handle data integrity.
5.  **Environment Logic**: 
    - Web: Auto-seeds concept data if boxes are empty.
    - Android: Initializes `Workmanager` for background tasks (midnight sync/engine).
6.  **ProviderScope**: Wraps the entire app to enable Riverpod state management.

## 2. Global State & App Layer (`lib/app.dart`)
### Key Components:
- **Error Handling**: Overrides `ErrorWidget.builder` globally to provide a high-fidelity "Application Error" screen containing the exception and stack trace. This is critical for field debugging.
- **Routing**: Managed by `routerProvider`, which is reactively defined in `lib/router/app_router.dart`. It takes `hiveHealthy` as a parameter to handle fatal data errors.
- **FCM Navigation**: The `MaterialApp` is wrapped in a `Navigator` using the `FcmService.navigatorKey`, allowing the server to push navigation commands (kill signals) regardless of current navigation state.

## 3. Technology Stack
- **Framework**: Flutter
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Local Storage**: Hive (NoSQL)
- **Secure Storage**: Flutter Secure Storage (PIN/Hash)
- **Backend / Auth**: Firebase
- **Background Tasks**: Workmanager
