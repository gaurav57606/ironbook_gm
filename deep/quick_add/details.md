# Screen: QuickAddMemberScreen

## 1. Purpose
The `QuickAddMemberScreen` provides a high-efficiency entry point for gym owners to onboard walk-in members in under 60 seconds. It prioritizes speed, minimal input, and immediate billing.

## 2. Architecture & Modules
- **Location**: `lib/features/members/presentation/screens/quick_add_member_screen.dart`
- **State Management**: ConsumerStatefulWidget, using Riverpod.
- **Provider Access**: `membersProvider`, `planProvider`, and `paymentProvider`.

## 3. Workflow & Functionality
1. **Initial State**: Fetches available plans from the `planProvider`. If no plans are configured, it displays a warning with a "Configure in Settings" CTA.
2. **Member Input**: Captures `name` and `phone` via `AppTextField`.
3. **Plan Selection**: Interactive chips to select from pre-configured gym plans.
4. **Payment Management**: Selects a payment method (Cash, UPI, Card, Bank).
5. **Logic Sequence on Save**:
    - **Step 1: Save Member**: Calls `ref.read(membersProvider.notifier).addMember(...)`.
    - **Step 2: Persist Action**: Triggers internal `DomainEvent` (Member Joined) in the Hive database.
    - **Step 3: Record Payment**: Concurrent call to `paymentProvider.recordMemberPayment(...)` to generate an invoice.
    - **Step 4: Navigate to Receipt**: Immediate redirection to `InvoiceScreen` with the new `memberId`.

## 4. Connections & Interactions
- **Upstream**: Configured `Plan` objects from the settings module.
- **Downstream**: `InvoiceScreen` for immediate confirmation.
- **Side-Effects**: Local Hive updates (`members` and `payments` boxes).

## 5. Logic Safeguards
- **Pre-Validation**: Ensures non-empty name and at least one chosen plan.
- **Transaction Safety**: Although Hive is NOT transactional, use of events ensures any write failures can be audited via the event log.
- **Debounced Saving**: "Register" button is disabled during the asynchronous save operation to prevent duplicate entries.
- **Offline Persistence**: Works 100% offline, allowing gym owners to register members even with zero connectivity.

## 6. Dependencies
- `membersProvider` (Core CRUD)
- `planProvider` (Pricing Engine)
- `paymentProvider` (Billing Engine)
- `AppTextField` & `AppButton` (Core UI Components)
- `go_router` (Navigation Logic)
- `uuid` (Unique ID Generation)
