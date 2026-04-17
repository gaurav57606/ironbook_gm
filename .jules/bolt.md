## 2025-05-14 - [Refactored Long build method in SettingsScreen]
**Learning:** Large widget build methods with nested Column/ListView and complex logic (like dialogs) are difficult to maintain. Extracting them into private helper methods within the same State class is a low-risk way to improve readability without breaking Riverpod or context-dependent logic.
**Action:** Always look for logical "groups" in long build methods and extract them into named helper methods. Ensure context is passed if needed, or use the class-level context if available in State.
## 2025-05-14 - [Fixed CI Build Failure in Android assembleRelease]
**Learning:** In CI environments like GitHub Actions, release signing properties (key.properties) are often missing. This causes the `assembleRelease` task to fail if `signingConfig` is strictly assigned to `release`.
**Action:** Always wrap release `signingConfig` assignment in a check for the keystore properties file existence. Fall back to `debug` signing if missing to allow build verification to proceed.
