## 2024-05-18 - Single Loop Over Collections
**Learning:** Found multiple instances where the codebase was calculating derived count and list items (like `activeCount`, `expiringCount`) by performing multiple `.where((...).length` iterations on the same large list.
**Action:** Replace multiple sequential `.where` or `.map` calls over the same list with a single `for` loop traversal that updates local variables, avoiding O(N) traversals per metric.
