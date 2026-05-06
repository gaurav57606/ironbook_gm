## 2026-05-06 - Missing Firestore Rules for Security Keys
**Vulnerability:** The `device_keys` collection lacked Firestore rules, preventing cloud backup of HMAC keys.
**Learning:** Security features implemented in client code (like HMAC backup) can fail silently if the underlying infrastructure rules are not synchronized.
**Prevention:** Always verify that every new Firestore collection used in services has a corresponding rule in `firestore.rules`.

## 2026-05-06 - Weak Key Wrapping and Insecure Fallbacks
**Vulnerability:** AES wrapping keys were derived solely from the `userId`, and the app defaulted to a hardcoded secret.
**Learning:** Identity-based encryption is insufficient for cloud storage if the identity (UID) is the primary key. Multi-factor KDFs (UID + Server Secret) are mandatory for true data-at-rest protection in the cloud.
**Prevention:** Implement a "Security Gate" in `ConfigService` that prevents the app from running in production without all secrets explicitly defined.
