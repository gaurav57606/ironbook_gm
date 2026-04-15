## 2024-05-15 - [Initial memory setup]
## 2024-05-15 - [O(n) Single Pass Collection Derivations]
**Learning:** Chaining multiple `.where().length` or `.where().take()` calls on lists recalculates expensive derivations (like `DateTime.now()` and status evaluation) for every item across multiple passes.
**Action:** Replace chained collection filters with a single manual `for` loop and a `switch` statement when calculating multiple derived metrics or grouping values. Cache expensive constants (like `DateTime.now()`) outside the loop.
