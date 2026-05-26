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
## 2024-05-24 - [Avoid Provider Reads in Loops]\n**Learning:** Reading Riverpod providers (like ) inside a  or  loop causes the provider to be evaluated N times, which is a hidden performance bottleneck during widget builds.\n**Action:** Always extract provider reads and expensive computations outside of loops in UI build methods.
## 2024-05-24 - [Avoid Provider Reads in Loops]
**Learning:** Reading Riverpod providers (like `ref.watch(clockProvider).now`) inside a `List.generate` or `.map` loop causes the provider to be evaluated N times, which is a hidden performance bottleneck during widget builds.
**Action:** Always extract provider reads and expensive computations outside of loops in UI build methods.
## 2026-04-24 - [Hidden Costs of Dart Getters in Iteration]
**Learning:** The `status` property on `MemberSnapshot` is a dynamic getter that evaluates `DateTime.now()` and recalculates date differences each time it is accessed. Using this getter inside list operations like `.where((m) => m.status == ...)` causes hidden redundant evaluations, severely degrading performance for large lists.
**Action:** When filtering or folding lists based on time-dependent properties in Dart, always examine if the property is a dynamic getter. If so, cache `DateTime.now()` outside the loop and call the underlying calculation method explicitly (e.g., `m.getStatus(now)`) inside the loop.
## 2024-05-24 - [Avoid Event Log Fetch Optimization Pitfall]
**Learning:** When reconstructing historical snapshots, do not attempt to "optimize" database fetches by using a previously cached/partial list of events (like `_repo.getAll()` which might only return local/unsynced events). Rebuilding snapshots from an incomplete event list leads to missing data and corruption.
**Action:** Always fetch the complete event history for an entity (e.g. `await _repo.getByEntityId(entityId)`) when reconstructing snapshots to ensure accuracy and prevent data corruption, even if it requires an extra DB query.

## 2024-05-24 - [Avoid Race Conditions During App Initialization]
**Learning:** Registering asynchronous listeners (like a real-time event bus listener) before fully populating an initial state can lead to race conditions. If an event fires while the initial state is still loading, the listener's update may be overwritten by the completion of the initial state load.
**Action:** Always ensure the initial state is fully loaded and reconciled before registering real-time listeners.
## 2024-05-24 - [Avoid `Future.wait` Memory Bloat on Hive `LazyBox`]
**Learning:** Fetching all keys from a Hive `LazyBox` at once and mapping them to `box.get(key)` inside a single `Future.wait` forces all records into memory simultaneously. For large databases, this completely defeats the purpose of a `LazyBox` and causes severe memory spikes or Out-Of-Memory (OOM) crashes.
**Action:** When performing bulk reads from a `LazyBox`, always batch the keys into smaller chunks (e.g., using `skip().take(50)`) and use `Future.wait` *within* each chunk. This preserves the speed of parallel I/O while strictly capping peak memory usage.

## 2025-01-24 - Logout Process Optimization
**Learning:** Clearing multiple Hive boxes and Drift tables sequentially during logout can be a performance bottleneck as the number of data stores grows.
**Action:** Use `Future.wait` to parallelize Hive box clearing and Drift's `batch` API to clear all tables in a single transaction. This reduced execution time by ~40% in benchmarks.

## 2025-05-27 - Batch Database Operations
**Learning:** Looping over `repository.getSale(saleId)` followed by `repository.applyEvent(event)` creates an N+1 query and transactional overhead bottleneck during reconciliation processes (e.g. `SaleNotifier._reconcileSales`).
**Action:** When reconciling multiple events against the database, always extract the database lookups into a single batched query (e.g., `getAllSaleIds()`) and extract individual updates into a single batched write operation (e.g. `upsertSales()` using Drift's `batch` API).
