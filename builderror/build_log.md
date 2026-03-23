# Build Error Log

This file tracks all failed Codemagic build attempts for the IronBook GM project.

| Build # | Date/Time (Estimated) | Step Failed | Reason / Error Snippet |
|---------|-----------------------|-------------|------------------------|
| 1-4     | 2026-03-23 | Build Android APK | `cannot find symbol: class Registrar` (V1 Embedding Error) |
| 5       | 2026-03-23 | Build Android APK | `NDK version = 25.1.8937393 is required.` |
| 6       | 2026-03-23 | Build Android APK | `compileSdk = 35` required by lifecycle plugin. |
| 8       | 2026-03-23 | Build Android APK | `Couldn't find constructor 'CardThemeData'` (Dart Typo) |
| 11      | 2026-03-23 | Build Android APK | `Binary metadata 2.1.0, expected 1.9.0` (Kotlin Mismatch) |
| 13      | 2026-03-23 | Clean workspace | `line 4: ./gradlew: No such file or directory` (Path Error) |
| 14      | 2026-03-23 17:00 | Clean workspace | `chmod: gradlew: No such file or directory` (Path Error) |
