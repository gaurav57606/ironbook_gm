## 2025-05-14 - [Refactored Long build method in SettingsScreen]
**Learning:** Large widget build methods with nested Column/ListView and complex logic (like dialogs) are difficult to maintain. Extracting them into private helper methods within the same State class is a low-risk way to improve readability without breaking Riverpod or context-dependent logic.
**Action:** Always look for logical "groups" in long build methods and extract them into named helper methods. Ensure context is passed if needed, or use the class-level context if available in State.
