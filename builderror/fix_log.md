# Fix History Log

This file tracks the fixes suggested for build errors and their implementation status.

| Build # | Suggested Fix | Applied? | Pushed to Git? | Status |
|---------|---------------|----------|----------------|--------|
| 1-4     | Upgrade `purchases_flutter` to ^8.1.1 | Yes | Yes | Resolved |
| 5       | Set `ndkVersion = "25.1.8937393"` in build.gradle.kts | Yes | Yes | Resolved |
| 6       | Set `compileSdk = 35` in build.gradle.kts | Yes | Yes | Resolved |
| 8       | Change `CardThemeData` to `CardTheme` in app_theme.dart | Yes | Yes | Resolved |
| 11      | Force Kotlin 2.1.0 using resolutionStrategy | Yes | Yes | Resolved |
| 13      | Fix path to gradlew in codemagic.yaml | Yes | Yes | Failed (chmod issue) |
| 14      | Simplify CI script to `flutter clean` only | Yes | Yes | Applied (Awaiting #15) |
