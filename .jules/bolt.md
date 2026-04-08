## 2024-05-24 - Avoid Chained Iterable Filters on Render Paths
**Learning:** Chaining multiple `.where().length` calls on Riverpod domain lists (like members) within `build` methods causes O(N * C) redundant iterations and unnecessary repetitive cache evaluations (e.g., re-evaluating `getStatus(now)`).
**Action:** Always prefer a single `for` loop with a `switch` statement when aggregating multiple metrics or sub-lists from the same source list. Additionally, cache dependencies like `DateTime.now()` outside the loop.
