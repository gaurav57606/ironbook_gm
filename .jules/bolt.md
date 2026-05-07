## 2024-05-22 - [Secondary Indexing for LazyBox]
**Learning:** Iterating over all keys in a Hive LazyBox to filter by a property (like entityId) results in an N+1 query pattern, which is extremely slow as the box grows. Maintaining an in-memory index of property value to keys allows for O(1) key lookup and only fetching the necessary records.
**Action:** Always implement secondary indexes for frequent non-primary-key queries when using Hive LazyBox. Use a Future-based concurrency lock (like _loadingIndex) to ensure the index is only built once during the first access.
## 2026-05-07 - Single Pass Optimizations
**Learning:** Multiple chained `.where(...).length` calls for deriving different status counts on lists in UI `build()` methods create unnecessary O(N) operations and repeat expensive object-level method evaluation (e.g. `getStatus()`).
**Action:** Replaced chained filter/map statements with a single `for` iteration to count multiple derived metrics simultaneously, minimizing operations.
