## 2024-03-20 - Avoid try-catch with firstWhere in Dart
**Learning:** In Dart, using `try { list.firstWhere(...) } catch (_) { return null; }` is a performance anti-pattern. Catching `StateError` is computationally expensive due to stack trace generation and risks masking other unexpected exceptions. The `where(...).firstOrNull` pattern (available in Dart 3.0+) is much faster and cleaner for paths where an element might not exist.
**Action:** Replace `try-catch` blocks around `firstWhere` with `where(...).firstOrNull` whenever looking up an item that might not be found.
