# Screen: PosScreen

## 1. Purpose
The `PosScreen` (Point of Sale) manages on-site retail for the gym. It handles supplement inventory sales and merchandise transactions, ensuring every side-sale is tracked against the gym's revenue.

## 2. Architecture & Modules
- **Location**: `lib/features/billing/presentation/screens/pos_screen.dart`
- **State Management**: `PosNotifier` (Cart state) and `SaleNotifier` (Persistence).
- **Provider Access**: `productsProvider` (Available stock) and `saleProvider` (Write Path).

## 3. Workflow & Functionality
1. **Product Selection**: Interactive grid of supplements/merchandise with category filtering.
2. **Cart Logic**: Ephemeral local state tracks quantities during a session.
3. **Checkout (Charge)**: 
    - Generates a unique `saleId` and `SAL-YYYY-...` invoice sequence number.
    - Persists a `Sale` record to Hive (`sales` box).
    - Emits a `SALE_RECORDED` Domain Event to the audit log.
4. **Billing Integration**: Directly updates the financial transaction log available in the admin dashboard.

## 4. Connections & Interactions
- **Upstream**: Product inventory seeded from `SaleNotifier`.
- **Downstream**: Cloud Sync via `SyncWorker` (Pushes sales to Firestore for global reporting).
- **Side-Effects**: UI confirmation via SnackBar upon successful persistence.

## 5. Logic Safeguards
- **Loading UI**: Disables the 'Charge' button during asynchronous persistence to prevent duplicate billing.
- **Cart Validation**: Prevents checkout if the cart is empty.
- **HMAC Signatures**: Every recorded sale event is cryptographically signed to prevent manual tampering with revenue records.

## 6. Dependencies
- `productsProvider` (Inventory)
- `saleProvider` (Persistence and Log Engine)
- `AppButton` & `StatusBarWrapper` (UI)
- `lucide_icons` (Aesthetics)
