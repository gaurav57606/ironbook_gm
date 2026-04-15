## 2024-05-15 - Array Iteration Performance
**Learning:** Dart collections chained with `.where().length` evaluate eagerly and traverse the list multiple times, which is a significant bottleneck on list screens (e.g., Dashboards) where status calculations require computing days remaining dynamically (`DateTime.now()`).
**Action:** Always combine multi-status counting into a single manual `for` loop using a `switch` statement and cache expensive initializations like `DateTime.now()` outside the loop.
