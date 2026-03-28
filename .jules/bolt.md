## 2024-05-15 - Using firstOrNull instead of try-catch with firstWhere
**Learning:** In Dart 3.0+, using `firstOrNull` on collections (from `package:collection/collection.dart` or built-in iterables like `.where(...).firstOrNull`) is more performant than wrapping `firstWhere` in a `try-catch` block. Catching `StateError` is inefficient and can mask other unexpected exceptions.
**Action:** Replace `try { list.firstWhere(...) } catch (_) { return null; }` with `list.where(...).firstOrNull`.
