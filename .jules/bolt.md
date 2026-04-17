## 2024-05-22 - [Secondary Indexing for LazyBox]
**Learning:** Iterating over all keys in a Hive LazyBox to filter by a property (like entityId) results in an N+1 query pattern, which is extremely slow as the box grows. Maintaining an in-memory index of property value to keys allows for O(1) key lookup and only fetching the necessary records.
**Action:** Always implement secondary indexes for frequent non-primary-key queries when using Hive LazyBox. Use a Future-based concurrency lock (like _loadingIndex) to ensure the index is only built once during the first access.
