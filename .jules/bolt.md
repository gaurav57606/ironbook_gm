## 2025-05-14 - [Code Health: Extracted Long Functions]
**Learning:** Large build methods in Flutter screens reduce readability and make it harder to identify the logical structure of the UI. Extracting complex sections (like Sliders or multi-child columns) into private helper methods significantly improves maintainability.
**Action:** Always look for logical "blocks" in a build method that can be isolated into descriptive private methods, especially when they involve complex themes or state-dependent logic.
