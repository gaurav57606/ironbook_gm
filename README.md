# IronBook GM

**IronBook GM** is a local-first, high-performance Gym Management system designed for solo owners. It prioritizes data integrity, offline reliability, and cryptographic security.

## 🚀 Key Features

- **Local-First Architecture**: Operations are performed instantly on the device. Syncing to the cloud is a passive background process.
- **Event-Sourced Sync**: All changes are recorded as domain events in a persistent outbox, ensuring 100% reconciliation accuracy.
- **Cryptographic Integrity**: All local snapshots are HMAC-signed to prevent unauthorized data tampering.
- **Gym Leader Profile**: Dynamic business metrics transformed into RPG-style character stats.
- **Modular Design**: Clean separation between `core` (logic), `features` (UI), and `shared` (widgets).

## 🛠 Tech Stack

- **Framework**: Flutter 3.22+
- **State Management**: Riverpod 2.x
- **Local Authorities**: Hive (Cache/Snapshots) & Drift (Persistent Outbox)
- **Security**: HMAC SHA-256, Biometrics, Entitlement Heartbeat
- **Infrastructure**: Firebase (Cloud Backup), Workmanager (Background Sync)

## 📦 Project Structure

```text
lib/
├── core/
│   ├── data/        # Repositories, Models, Drift/Hive setup
│   ├── providers/   # Global business logic providers
│   ├── security/    # HMAC, PIN, and Entitlement guards
│   ├── services/    # Infrastructure (PDF, Config, Logger)
│   └── sync/        # Background workers and recovery logic
├── features/        # Feature-based UI modules
│   ├── auth/
│   ├── members/
│   ├── pos/
│   └── backup/
└── shared/          # Common widgets and utilities
```

## 🛠 Setup & Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/gaurav57606/ironbook_gm.git
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment**:
   Copy `.env.example` to `.env` and fill in your keys.

4. **Run Build Runner** (if modifying models):
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Launch**:
   ```bash
   flutter run
   ```

## 🧪 Testing

Run the full suite of unit and integration tests:
```bash
flutter test
```

## 🏗 Build for Web

```bash
bash render_build.sh
```

---
*Built with ❤️ by the IronBook Team.*
