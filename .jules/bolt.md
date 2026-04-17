## 2026-04-17 - [Optimizing Hive LazyBox fetch with Future.wait]
**Learning:** Sequential 'await' in a loop for LazyBox.get(key) creates an N+1 query pattern. Even though LazyBox is asynchronous, fetching keys in parallel using Future.wait allows the underlying system to potentially optimize disk I/O or at least avoid the overhead of sequential task scheduling.
**Action:** Use Future.wait when fetching multiple items from a Hive LazyBox by their keys.
