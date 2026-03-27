# Screen: InvoiceScreen

## 1. Purpose
The `InvoiceScreen` provides high-fidelity digital receipts for gym memberships and add-on sales. It is designed to be professional, branded, and shareable, serving as a key trust-building component for solo gym owners.

## 2. Architecture & Modules
- **Location**: `lib/features/billing/presentation/screens/invoice_screen.dart`
- **State Management**: Uses `ref.watch(paymentProvider)` to fetch historical transaction data.
- **Provider**: `paymentProvider` (manages `Payment` model collection and `InvoiceSequence`).

## 3. Workflow & Functionality
1. **Navigation**: Typically reached from `QuickAddMemberScreen` or `MemberDetailScreen` via `context.push('/invoice?memberId=XYZ')`.
2. **Data Fetching**: The screen retrieves the latest `Payment` record for the given `memberId`.
3. **Layout Generation**: Builds a skeletal, high-contrast UI that mimics a physical receipt.
4. **Calculations**:
    - **Subtotal**: Calculated as `Total / 1.18` (extracting GST).
    - **GST (18%)**: Automatically calculated and itemized for professional compliance.
5. **Sharing Pipeline**:
    - **WhatsApp**: Triggers a direct WhatsApp message with the receipt summary.
    - **Share (Image/PDF)**: Uses `share_plus` and `printing` to generate a shareable asset from the screen view.

## 4. Connections & Interactions
- **Connected to `MemberSnapshot`**: Displays member name and phone.
- **Connected to `Payment`**: Displays invoice number, amount, date, and selected plan components.
- **Logic Safeguard**: If no payment record is found, it renders an error state with a "Back to Dashboard" fallback.

## 5. Logic Safeguards
- **Persistence**: Relies on Hive's `Box<Payment>` which is HMAC-signed for integrity.
- **Offline Ready**: Works 100% offline as it reads from local cache.
- **Unique Scoping**: Invoices are scoped to unique `memberId` to prevent data leakage between memberships.

## 6. Dependencies
- `paymentProvider` (Billing Logic)
- `membersProvider` (Member Metadata)
- `AppColors` (Thematic Consistency)
- `share_plus` (External Integration)
- `pdf` & `printing` (Document Generation)
- `Intl` (Currency and Date Formatting)
