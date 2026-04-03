## 2024-04-03 - Safely Batch DB Writes Without Breaking DI
**Learning:** Accumulating state variables for database bulk inserts can massively speed up I/O inside loops, but modifying architectural bindings like Riverpod instance services into static singletons to fix syntax limits will easily break CI tests.
**Action:** Use maps/batches for bulk I/O, and pass provider dependencies explicitly instead of resorting to static properties.
