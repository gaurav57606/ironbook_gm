## 2024-05-22 - [Secondary Indexing for LazyBox]
**Learning:** Iterating over all keys in a Hive LazyBox to filter by a property (like entityId) results in an N+1 query pattern, which is extremely slow as the box grows. Maintaining an in-memory index of property value to keys allows for O(1) key lookup and only fetching the necessary records.
**Action:** Always implement secondary indexes for frequent non-primary-key queries when using Hive LazyBox. Use a Future-based concurrency lock (like _loadingIndex) to ensure the index is only built once during the first access.
## 2024-05-23 - [Single Pass List Iteration for Multi-Stats]
**Learning:** Chaining multiple `.where().length` or `.take()` calls on a list inside build methods (like computing active, expiring, expired member counts) repeats list iteration and re-evaluates expensive item methods like `DateTime.now().difference()`.
**Action:** When computing multiple derivations from a single list in Flutter UI classes, always use a single manual `for` loop with a `switch` or `if/else` block. Cache expensive arguments like `DateTime.now()` outside the loop. This reduces computation from O(k*N) to O(N) and limits expensive method evaluations.
## 2024-05-24 - File Read Truncation in Environment
**Learning:** Tools like `cat` or `read_file` may silently truncate large files in this environment, leading to partial context and hallucinated refactoring plans.
**Action:** When working with large files, always verify the end of the file output. If truncated, use `sed -n 'X,Yp' <filepath>` to read the code in chunks before planning modifications.

## 2024-05-24 - Strict Enforcement of Dependency File Boundaries
**Learning:** Running commands like `flutter pub get` or test execution in this environment can unexpectedly update `pubspec.lock` (e.g., bumping SDK versions), which triggers a blocking review failure. The instruction "Never modify package.json" strictly applies to its Dart equivalent, `pubspec.lock`.
**Action:** Always run `git status` after local commands and use `git restore pubspec.lock` (or `--staged`) to explicitly discard any unintended dependency or SDK version bumps before submitting a PR.
