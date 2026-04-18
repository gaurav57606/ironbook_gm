## 2024-05-22 - [Secondary Indexing for LazyBox]
**Learning:** Iterating over all keys in a Hive LazyBox to filter by a property (like entityId) results in an N+1 query pattern, which is extremely slow as the box grows. Maintaining an in-memory index of property value to keys allows for O(1) key lookup and only fetching the necessary records.
**Action:** Always implement secondary indexes for frequent non-primary-key queries when using Hive LazyBox. Use a Future-based concurrency lock (like _loadingIndex) to ensure the index is only built once during the first access.

## 2025-10-23 - [Batching Hive Puts]
**Learning:** In scenarios like Firestore recovery, continuously awaiting `Hive.box.put()` inside a loop over a large dataset results in excessive disk I/O and stalls the event loop.
**Action:** Accumulate database write models into an in-memory `Map` during processing, and write them in a single operation using `Hive.box.putAll()` after the loop.
