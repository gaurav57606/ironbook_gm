# Screen: PinSetupScreen

## Purpose
Setting up a 4-digit security PIN for data privacy.

## Features
- Double-entry verification (PIN + Confirm PIN).
- Biometric (FaceID/Fingerprint) toggle.

## Logic
- PIN is hashed and stored in local `AuthCache`.
- HMAC signing key is derived from this PIN for event integrity.

## Dependencies
- `authProvider`
- `local_auth` (Biometrics)
