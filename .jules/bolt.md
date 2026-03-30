## 2024-05-19 - Using firstOrNull instead of firstWhere + try-catch
**Learning:** In Dart 3, `firstWhere` wrapped in a `try-catch` block (catching `StateError`) to find an element that might not exist in a collection is inefficient because catching `StateError` is slow and it can mask other unexpected exceptions. The `where(...).firstOrNull` pattern is the correct convention to use for safe lookup.
**Action:** Replace `firstWhere` wrapped in `try-catch` with `.where(...).firstOrNull` where applicable.
