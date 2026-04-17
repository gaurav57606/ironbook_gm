## 2024-05-22 - [Optimized LazyBox Iteration with Batching]
**Learning:** Sequential `await box.get(key)` in Hive `LazyBox` loops introduces significant micro-task overhead.
**Action:** Use `Future.wait` to fetch snapshots in batches (e.g., size 50-100). This parallelizes the disk I/O requests and reduces the number of await cycles, significantly improving performance for large datasets while maintaining the memory benefits of a lazy box.
