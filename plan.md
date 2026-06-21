1. **Add `upsertSales` and `getAllSaleIds` to `ISaleRepository` and `DriftSaleRepository`**
   - Introduce a `_toCompanion` helper method in `DriftSaleRepository` to share mapping logic between `upsertSale` and `upsertSales`.
   - Implement `upsertSales` using Drift's `batch` API and `InsertMode.insertOrReplace` to efficiently write multiple sales in a single transaction.
   - Implement `getAllSaleIds` to fetch just the IDs of all sales, reducing memory bloat compared to loading entire objects.

2. **Optimize `SaleNotifier._reconcileSales`**
   - Replace the sequential database reads (`_saleRepo.getSale(saleId)`) inside the loop with an O(1) in-memory check using `state.map((s) => s.id).toSet()`.
   - Replace individual `_saleRepo.applyEvent(event)` calls inside the loop with a single batch operation by converting missing events to `Sale` objects and passing them to `_saleRepo.upsertSales(newSales)`.

3. **Verify and test**
   - Run linter and tests to ensure correctness and no regressions.
   - Proceed to submit a PR if everything is passing and optimized.
