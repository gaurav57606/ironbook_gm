# IronBook GM — Complete Flutter App Transformation Blueprint

> **Purpose:** A complete, action-ready prompt for Claude/AI to transform the IronBook GM Flutter gym management app into a stable, lightweight, error-resilient, and modular production app. Hand this prompt to your AI coding assistant to execute the full refactor.

---

## Context & Goal

The current IronBook GM Flutter app suffers from cascading bugs — fixing one screen breaks another. The goal of this transformation is:

1. **Lock each screen** — once a screen is built and tested, it stays correct regardless of changes elsewhere
2. **Stable architecture** — no spaghetti dependencies between screens
3. **Lightweight on Android** — minimal RAM, fast startup, smooth 60fps
4. **Easy debugging** — when an error occurs, its source is immediately obvious and isolated
5. **Modular** — features can be added or removed without touching unrelated code

---

## PART 1 — FILES TO DELETE (Clean Slate)

Delete the following files/folders entirely. These represent the old unstructured approach:

### Root-level files to delete
```
lib/main.dart              ← will be recreated from scratch
lib/home_screen.dart       ← replace with modular routing
lib/dashboard.dart         ← replace with feature-based structure
```

### Any files matching these patterns (delete all):
```
lib/*_screen.dart          ← all old screens (will be rebuilt in features/)
lib/*_page.dart            ← all old pages
lib/*_widget.dart          ← all old loose widgets
lib/models/*.dart          ← old models (will be type-safe versions)
lib/utils/*.dart           ← old utilities
lib/db*.dart               ← any direct database access files
lib/helper*.dart           ← loose helper files
lib/constants.dart         ← will be split into proper constants
```

### Android-specific bloat to remove
```
android/app/src/main/res/drawable-*/   ← unused image assets
android/app/src/main/res/mipmap-*/     ← keep only launcher icons needed
assets/images/unused_*                 ← any unused image assets
```

---

## PART 2 — NEW FOLDER STRUCTURE TO CREATE

Create the following directory structure exactly:

```
lib/
├── main.dart                          ← app entry point (minimal)
├── app.dart                           ← MaterialApp + ThemeData + Router
│
├── core/
│   ├── constants/
│   │   ├── app_colors.dart            ← all colors
│   │   ├── app_text_styles.dart       ← all text styles
│   │   ├── app_spacing.dart           ← padding/margin constants
│   │   └── app_strings.dart           ← all hardcoded strings
│   │
│   ├── theme/
│   │   └── app_theme.dart             ← ThemeData light + dark
│   │
│   ├── router/
│   │   └── app_router.dart            ← GoRouter or Navigator 2.0 routes
│   │
│   ├── errors/
│   │   ├── app_error.dart             ← custom error types
│   │   └── error_handler.dart         ← global error catching
│   │
│   ├── utils/
│   │   ├── date_utils.dart
│   │   ├── string_utils.dart
│   │   └── validators.dart
│   │
│   └── extensions/
│       ├── context_extensions.dart    ← BuildContext helpers
│       └── string_extensions.dart
│
├── data/
│   ├── local/
│   │   ├── database/
│   │   │   ├── app_database.dart      ← Drift/Hive/Isar setup
│   │   │   └── database_constants.dart
│   │   └── preferences/
│   │       └── app_preferences.dart   ← SharedPreferences wrapper
│   │
│   ├── models/
│   │   ├── member.dart                ← Member model (freezed)
│   │   ├── payment.dart               ← Payment model (freezed)
│   │   ├── plan.dart                  ← Plan model (freezed)
│   │   └── attendance.dart            ← Attendance model (freezed)
│   │
│   └── repositories/
│       ├── member_repository.dart
│       ├── payment_repository.dart
│       ├── plan_repository.dart
│       └── attendance_repository.dart
│
├── domain/
│   ├── usecases/
│   │   ├── member/
│   │   │   ├── add_member_usecase.dart
│   │   │   ├── get_members_usecase.dart
│   │   │   └── update_member_status_usecase.dart
│   │   ├── payment/
│   │   │   ├── record_payment_usecase.dart
│   │   │   └── get_payment_history_usecase.dart
│   │   └── attendance/
│   │       └── mark_attendance_usecase.dart
│   └── interfaces/
│       ├── i_member_repository.dart
│       ├── i_payment_repository.dart
│       └── i_attendance_repository.dart
│
├── features/
│   ├── dashboard/
│   │   ├── presentation/
│   │   │   ├── dashboard_screen.dart
│   │   │   └── widgets/
│   │   │       ├── stat_card.dart
│   │   │       └── quick_actions_row.dart
│   │   └── viewmodel/
│   │       └── dashboard_viewmodel.dart
│   │
│   ├── members/
│   │   ├── presentation/
│   │   │   ├── members_list_screen.dart
│   │   │   ├── member_detail_screen.dart
│   │   │   ├── add_member_screen.dart
│   │   │   └── widgets/
│   │   │       ├── member_card.dart
│   │   │       └── member_status_badge.dart
│   │   └── viewmodel/
│   │       └── members_viewmodel.dart
│   │
│   ├── payments/
│   │   ├── presentation/
│   │   │   ├── payments_screen.dart
│   │   │   ├── record_payment_screen.dart
│   │   │   └── widgets/
│   │   │       └── payment_tile.dart
│   │   └── viewmodel/
│   │       └── payments_viewmodel.dart
│   │
│   ├── attendance/
│   │   ├── presentation/
│   │   │   ├── attendance_screen.dart
│   │   │   └── widgets/
│   │   │       └── attendance_row.dart
│   │   └── viewmodel/
│   │       └── attendance_viewmodel.dart
│   │
│   └── settings/
│       ├── presentation/
│       │   └── settings_screen.dart
│       └── viewmodel/
│           └── settings_viewmodel.dart
│
└── shared/
    ├── widgets/
    │   ├── app_button.dart            ← single reusable button widget
    │   ├── app_text_field.dart        ← single reusable text field
    │   ├── loading_indicator.dart
    │   ├── error_view.dart            ← reusable error display
    │   ├── empty_state_view.dart      ← reusable empty state
    │   └── confirmation_dialog.dart
    └── hooks/
        └── use_lifecycle.dart         ← flutter_hooks if used
```

---

## PART 3 — pubspec.yaml (EXACT DEPENDENCIES)

Replace current `pubspec.yaml` dependencies section with exactly these. Remove ALL unused packages:

```yaml
name: ironbook_gm
description: IronBook Gym Management App
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'
  flutter: '>=3.10.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management — lightweight, no boilerplate
  riverpod: ^2.5.1
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^13.2.0

  # Local Database — lightweight, pure Dart, no native code
  isar: ^3.1.0
  isar_flutter_libs: ^3.1.0
  path_provider: ^2.1.2

  # Immutable Models
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0

  # Preferences
  shared_preferences: ^2.2.3

  # UI Utilities
  flutter_svg: ^2.0.10+1
  intl: ^0.19.0
  gap: ^3.0.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.2
  build_runner: ^2.4.8
  riverpod_generator: ^2.3.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  isar_generator: ^3.1.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
```

**Packages being REMOVED (causes of bloat/instability):**
- `get` or `getx` — replace with Riverpod
- `provider` (standalone) — replaced by Riverpod
- `sqflite` — replaced by Isar (faster, no raw SQL errors)
- `firebase_*` — remove if not essential (heavy on Android)
- `dio` — remove if no network needed (this is a local app)
- `http` — remove if no network needed
- Any unused animation packages

---

## PART 4 — CORE FILES TO BUILD

### 4.1 — `lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'app.dart';
import 'data/models/member.dart';
import 'data/models/payment.dart';
import 'data/models/attendance.dart';

late Isar isar;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock to portrait only (lighter for a management app)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Initialize database
  final dir = await getApplicationDocumentsDirectory();
  isar = await Isar.open(
    [MemberSchema, PaymentSchema, AttendanceSchema],
    directory: dir.path,
  );
  
  runApp(
    const ProviderScope(
      child: IronBookApp(),
    ),
  );
}
```

### 4.2 — `lib/app.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class IronBookApp extends ConsumerWidget {
  const IronBookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'IronBook GM',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### 4.3 — `lib/core/router/app_router.dart`
```dart
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/members/presentation/members_list_screen.dart';
import '../../features/members/presentation/member_detail_screen.dart';
import '../../features/members/presentation/add_member_screen.dart';
import '../../features/payments/presentation/payments_screen.dart';
import '../../features/attendance/presentation/attendance_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(path: '/dashboard', builder: (c, s) => const DashboardScreen()),
      GoRoute(path: '/members', builder: (c, s) => const MembersListScreen()),
      GoRoute(path: '/members/add', builder: (c, s) => const AddMemberScreen()),
      GoRoute(
        path: '/members/:id',
        builder: (c, s) => MemberDetailScreen(memberId: int.parse(s.pathParameters['id']!)),
      ),
      GoRoute(path: '/payments', builder: (c, s) => const PaymentsScreen()),
      GoRoute(path: '/attendance', builder: (c, s) => const AttendanceScreen()),
      GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
    ],
  );
});
```

### 4.4 — `lib/data/models/member.dart` (Isar + Freezed)
```dart
import 'package:isar/isar.dart';

part 'member.g.dart';

@collection
class Member {
  Id id = Isar.autoIncrement;

  late String name;
  late String phone;
  late String planName;
  late DateTime joinDate;
  late DateTime expiryDate;
  late bool isActive;
  String? photoPath;

  // Computed — no stored field needed
  bool get isExpired => DateTime.now().isAfter(expiryDate);
  
  int get daysLeft => expiryDate.difference(DateTime.now()).inDays;
}
```

### 4.5 — `lib/data/repositories/member_repository.dart`
```dart
import 'package:isar/isar.dart';
import '../../main.dart';
import '../models/member.dart';

class MemberRepository {
  Future<List<Member>> getAllMembers() async {
    return isar.members.where().findAll();
  }

  Future<List<Member>> getActiveMembers() async {
    return isar.members.filter().isActiveEqualTo(true).findAll();
  }

  Future<Member?> getMemberById(int id) async {
    return isar.members.get(id);
  }

  Future<int> addMember(Member member) async {
    return isar.writeTxn(() => isar.members.put(member));
  }

  Future<void> updateMember(Member member) async {
    await isar.writeTxn(() => isar.members.put(member));
  }

  Future<void> deleteMember(int id) async {
    await isar.writeTxn(() => isar.members.delete(id));
  }

  Stream<List<Member>> watchAllMembers() {
    return isar.members.where().watch(fireImmediately: true);
  }
}

// Riverpod provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository();
});
```

### 4.6 — `lib/features/members/viewmodel/members_viewmodel.dart`
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../data/models/member.dart';
import '../../../data/repositories/member_repository.dart';

part 'members_viewmodel.g.dart';

@riverpod
class MembersViewModel extends _$MembersViewModel {
  @override
  Stream<List<Member>> build() {
    final repo = ref.watch(memberRepositoryProvider);
    return repo.watchAllMembers();
  }

  Future<void> addMember(Member member) async {
    final repo = ref.read(memberRepositoryProvider);
    await repo.addMember(member);
  }

  Future<void> deleteMember(int id) async {
    final repo = ref.read(memberRepositoryProvider);
    await repo.deleteMember(id);
  }
}
```

### 4.7 — `lib/shared/widgets/error_view.dart`
```dart
import 'package:flutter/material.dart';

class ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}
```

### 4.8 — Screen template (LOCK PATTERN — use for every screen)
Every screen must follow this exact pattern. This is what "locking" a screen means:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodel/members_viewmodel.dart';
import '../../../shared/widgets/error_view.dart';
import '../widgets/member_card.dart';

// ✅ LOCKED SCREEN — Do not modify widget tree after testing
class MembersListScreen extends ConsumerWidget {
  const MembersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(membersViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: membersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorView(
          message: 'Failed to load members',
          onRetry: () => ref.invalidate(membersViewModelProvider),
        ),
        data: (members) => members.isEmpty
            ? const EmptyStateView(message: 'No members yet. Add your first member!')
            : ListView.builder(
                itemCount: members.length,
                itemBuilder: (ctx, i) => MemberCard(member: members[i]),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/members/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

---

## PART 5 — ANDROID OPTIMIZATION CHANGES

### 5.1 — `android/app/build.gradle` changes
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21          // covers 99%+ of devices
        targetSdkVersion 34
        multiDexEnabled true
    }
    
    buildTypes {
        release {
            minifyEnabled true        // ← ENABLE THIS (removes dead code)
            shrinkResources true      // ← ENABLE THIS (removes unused assets)
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'),
                          'proguard-rules.pro'
            signingConfig signingConfigs.release
        }
    }
    
    // Reduce APK size — only build for ARM (most Android devices)
    splits {
        abi {
            enable true
            reset()
            include "arm64-v8a", "armeabi-v7a"
            universalApk false
        }
    }
}
```

### 5.2 — `android/app/proguard-rules.pro`
```proguard
# Isar
-keep class com.isar.** { *; }
-keep class dev.isar.** { *; }

# Freezed models
-keep class **.freezed.dart { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.**
```

### 5.3 — `android/app/src/main/AndroidManifest.xml` additions
```xml
<application
    android:hardwareAccelerated="true"
    android:largeHeap="false"
    ...>
```
Set `largeHeap="false"` — forces the app to be memory-efficient instead of grabbing extra heap.

---

## PART 6 — FLUTTER PERFORMANCE RULES (apply to every widget)

Add these rules as a `CODING_STANDARDS.md` file in the project root:

### Rule 1 — const constructors everywhere
```dart
// ✅ Good — const = compiled once, never rebuilt
const Text('Members')
const SizedBox(height: 16)
const Icon(Icons.person)

// ❌ Bad
Text('Members')
SizedBox(height: 16)
```

### Rule 2 — No logic in build()
```dart
// ✅ Good — logic in ViewModel
Widget build(BuildContext context, WidgetRef ref) {
  final members = ref.watch(membersViewModelProvider);
  return MemberList(members: members.valueOrNull ?? []);
}

// ❌ Bad
Widget build(BuildContext context) {
  final filtered = allMembers.where((m) => m.isActive).toList(); // DON'T
  return ...;
}
```

### Rule 3 — Split large widgets
Any widget over 80 lines must be split into smaller widgets. This prevents the cascade-of-bugs issue.

### Rule 4 — Never use setState for shared data
```dart
// ✅ Good — Riverpod handles shared state
ref.watch(membersViewModelProvider)

// ❌ Bad — setState only for truly local UI state (animations, toggles)
setState(() { members = newList; }) // NEVER for data
```

### Rule 5 — Always handle AsyncValue states
```dart
// Every Riverpod stream/future MUST have all 3 states:
asyncValue.when(
  loading: () => const CircularProgressIndicator(),
  error: (e, s) => ErrorView(message: e.toString()),
  data: (data) => YourWidget(data: data),
);
```

---

## PART 7 — THE "LOCK" PATTERN IMPLEMENTATION

This is the core of your request — how to lock a screen once it works.

### Step 1 — Add a lock comment header to every completed screen
```dart
// ═══════════════════════════════════════════════════════════
// 🔒 LOCKED SCREEN — MembersListScreen
// Status: ✅ Tested & Stable
// Last tested: [date]
// Depends on: MembersViewModel, MemberCard, ErrorView
// DO NOT modify widget tree without running full test
// ═══════════════════════════════════════════════════════════
```

### Step 2 — Write a widget test for each locked screen
Create `test/features/members/members_list_screen_test.dart`:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ironbook_gm/features/members/presentation/members_list_screen.dart';

void main() {
  testWidgets('MembersListScreen shows loading initially', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: MembersListScreen())),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('MembersListScreen shows empty state when no members', (tester) async {
    // Override provider with empty list
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          membersViewModelProvider.overrideWith((ref) => Stream.value([])),
        ],
        child: const MaterialApp(home: MembersListScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('No members yet'), findsOneWidget);
  });
}
```

### Step 3 — Run `flutter test` before and after any change
If tests fail after a change — you know exactly what broke and where.

---

## PART 8 — FILES TO CREATE (Complete List)

### Create these files (in order):

| # | File Path | Purpose |
|---|-----------|---------|
| 1 | `lib/main.dart` | App entry, Isar init |
| 2 | `lib/app.dart` | MaterialApp + router |
| 3 | `lib/core/constants/app_colors.dart` | Color constants |
| 4 | `lib/core/constants/app_text_styles.dart` | Text style constants |
| 5 | `lib/core/constants/app_spacing.dart` | Spacing constants |
| 6 | `lib/core/constants/app_strings.dart` | All strings |
| 7 | `lib/core/theme/app_theme.dart` | ThemeData |
| 8 | `lib/core/router/app_router.dart` | GoRouter config |
| 9 | `lib/core/errors/app_error.dart` | Error types |
| 10 | `lib/core/utils/date_utils.dart` | Date helpers |
| 11 | `lib/core/utils/validators.dart` | Form validators |
| 12 | `lib/data/models/member.dart` | Member Isar model |
| 13 | `lib/data/models/payment.dart` | Payment Isar model |
| 14 | `lib/data/models/attendance.dart` | Attendance Isar model |
| 15 | `lib/data/models/plan.dart` | Plan Isar model |
| 16 | `lib/data/repositories/member_repository.dart` | Member DB ops |
| 17 | `lib/data/repositories/payment_repository.dart` | Payment DB ops |
| 18 | `lib/data/repositories/attendance_repository.dart` | Attendance DB ops |
| 19 | `lib/domain/interfaces/i_member_repository.dart` | Abstract interface |
| 20 | `lib/features/dashboard/presentation/dashboard_screen.dart` | Dashboard UI |
| 21 | `lib/features/dashboard/viewmodel/dashboard_viewmodel.dart` | Dashboard state |
| 22 | `lib/features/dashboard/presentation/widgets/stat_card.dart` | Stat widget |
| 23 | `lib/features/members/presentation/members_list_screen.dart` | Members list |
| 24 | `lib/features/members/presentation/add_member_screen.dart` | Add member form |
| 25 | `lib/features/members/presentation/member_detail_screen.dart` | Member detail |
| 26 | `lib/features/members/viewmodel/members_viewmodel.dart` | Members state |
| 27 | `lib/features/members/presentation/widgets/member_card.dart` | Member tile |
| 28 | `lib/features/members/presentation/widgets/member_status_badge.dart` | Status badge |
| 29 | `lib/features/payments/presentation/payments_screen.dart` | Payments list |
| 30 | `lib/features/payments/presentation/record_payment_screen.dart` | Add payment |
| 31 | `lib/features/payments/viewmodel/payments_viewmodel.dart` | Payment state |
| 32 | `lib/features/attendance/presentation/attendance_screen.dart` | Attendance |
| 33 | `lib/features/attendance/viewmodel/attendance_viewmodel.dart` | Attendance state |
| 34 | `lib/features/settings/presentation/settings_screen.dart` | Settings |
| 35 | `lib/shared/widgets/app_button.dart` | Reusable button |
| 36 | `lib/shared/widgets/app_text_field.dart` | Reusable text field |
| 37 | `lib/shared/widgets/loading_indicator.dart` | Loading widget |
| 38 | `lib/shared/widgets/error_view.dart` | Error widget |
| 39 | `lib/shared/widgets/empty_state_view.dart` | Empty state |
| 40 | `lib/shared/widgets/confirmation_dialog.dart` | Confirm dialog |
| 41 | `CODING_STANDARDS.md` | Dev rules reference |
| 42 | `test/features/members/members_list_screen_test.dart` | Screen test |

---

## PART 9 — BUILD ORDER (Do This Sequence)

Build in this exact order to avoid circular dependency issues:

```
Phase 1 — Foundation (no Flutter dependencies)
  → app_colors.dart
  → app_text_styles.dart
  → app_spacing.dart
  → app_strings.dart
  → date_utils.dart
  → validators.dart

Phase 2 — Data Layer
  → member.dart (Isar model + run build_runner)
  → payment.dart
  → attendance.dart
  → member_repository.dart
  → payment_repository.dart
  → attendance_repository.dart

Phase 3 — State Layer
  → members_viewmodel.dart (run build_runner again)
  → payments_viewmodel.dart
  → attendance_viewmodel.dart
  → dashboard_viewmodel.dart

Phase 4 — Shared UI
  → app_theme.dart
  → app_button.dart
  → app_text_field.dart
  → loading_indicator.dart
  → error_view.dart
  → empty_state_view.dart
  → confirmation_dialog.dart

Phase 5 — Feature Screens (one at a time, LOCK each before next)
  → dashboard_screen.dart  → TEST → LOCK
  → members_list_screen.dart → TEST → LOCK
  → add_member_screen.dart → TEST → LOCK
  → member_detail_screen.dart → TEST → LOCK
  → payments_screen.dart → TEST → LOCK
  → attendance_screen.dart → TEST → LOCK
  → settings_screen.dart → TEST → LOCK

Phase 6 — Wiring
  → app_router.dart
  → app.dart
  → main.dart
```

---

## PART 10 — CODE GENERATION COMMANDS

Run these commands after modifying any model or viewmodel:

```bash
# Generate Isar schemas + Riverpod code + Freezed models
flutter pub run build_runner build --delete-conflicting-outputs

# Run tests to verify nothing broke
flutter test

# Check for unused code
flutter analyze

# Build release APK (after optimization)
flutter build apk --release --split-per-abi
```

The `--split-per-abi` flag generates separate APKs per architecture — reduces APK size from ~20MB to ~8MB.

---

## PART 11 — CRITICAL RULES FOR AI ASSISTANT

When implementing this transformation, the AI assistant MUST:

1. **Never mix layers** — presentation widgets must NOT directly access Isar. Always go through Repository → ViewModel → Widget
2. **Always generate code** for Isar models using `build_runner` before using them
3. **Const everywhere** — every static widget must have the `const` keyword
4. **One ViewModel per feature** — never share viewmodels between features
5. **Error handling is mandatory** — every `async` function must have try/catch or use AsyncValue
6. **No `BuildContext` across async gaps** — always check `mounted` before using context after await
7. **Isar reads are fast** — use `.watch()` streams for live data, not manual refreshes
8. **Test before lock** — run `flutter test` before adding the 🔒 comment header

---

## PART 12 — MIGRATION CHECKLIST

Before calling the app complete, verify:

- [ ] All old files deleted
- [ ] `build_runner` ran successfully with zero errors
- [ ] `flutter analyze` shows zero issues
- [ ] All screens have the 🔒 lock header comment
- [ ] All screens have at least one widget test
- [ ] Release APK builds without errors (`flutter build apk --release --split-per-abi`)
- [ ] App opens in under 2 seconds on a mid-range device
- [ ] Member add/edit/delete flow works end-to-end
- [ ] Payment recording works end-to-end
- [ ] Attendance marking works end-to-end
- [ ] App works offline (no internet required)
- [ ] No crashes on empty database state
- [ ] Error views show correctly when database fails

---

*Generated for IronBook GM Flutter Gym Management App — Full Architecture Transformation*
