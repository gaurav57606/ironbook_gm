## 2026-04-17 - [Optimizing Hive LazyBox fetch with Future.wait]
**Learning:** Sequential 'await' in a loop for LazyBox.get(key) creates an N+1 query pattern. Even though LazyBox is asynchronous, fetching keys in parallel using Future.wait allows the underlying system to potentially optimize disk I/O or at least avoid the overhead of sequential task scheduling.
**Action:** Use Future.wait when fetching multiple items from a Hive LazyBox by their keys.
## 2026-04-17 - [Conditional Android Signing for CI]
**Learning:** In CI environments like GitHub Actions, release builds often fail because keystore files (e.g., key.properties) are missing. This causes Gradle to fail when it tries to access missing properties in the signingConfigs block.
**Action:** Wrap the signingConfig assignment in the buildTypes.release block with a check for the existence of the keystore properties file to ensure the build can still compile (e.g., for APK generation tests) even without production keys.
