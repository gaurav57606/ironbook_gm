import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/shared/utils/date_utils.dart';
import 'package:ironbook_gm/core/providers/payment_provider.dart';
import 'package:ironbook_gm/core/data/local/models/payment_model.dart';
import 'package:ironbook_gm/core/data/local/models/invoice_sequence.dart';
import 'package:ironbook_gm/core/data/local/models/plan_model.dart';
import 'package:ironbook_gm/core/data/local/models/plan_component_model.dart';
import 'package:ironbook_gm/core/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/data/repositories/payment_repository.dart';
import 'package:ironbook_gm/core/data/repositories/member_repository.dart';
import 'package:ironbook_gm/core/data/repositories/sequence_repository.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/core/data/local/models/domain_event_model.dart';
import 'package:ironbook_gm/core/services/sync_coordinator.dart';

class MockSequenceRepository extends Mock implements ISequenceRepository {}
class MockEventRepository extends Mock implements IEventRepository {}
class MockPaymentRepository extends Mock implements IPaymentRepository {}
class MockMemberRepository extends Mock implements IMemberRepository {}
class MockHmacService extends Mock implements HmacService {}
class MockSyncCoordinator extends Mock implements SyncCoordinator {}
class FakeDomainEvent extends Fake implements DomainEvent {}
class FakePayment extends Fake implements Payment {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDomainEvent());
    registerFallbackValue(FakePayment());
  });

  group('AppDateUtils Tests', () {
    test('addMonths: handles month overflow (Jan 31 + 1m = Feb 28)', () {
      final start = DateTime(2023, 1, 31);
      final end = AppDateUtils.addMonths(start, 1);
      expect(end.month, 2);
      expect(end.day, 28);
    });
  });

  group('PaymentNotifier Atomic Indexing Tests', () {
    late MockSequenceRepository sequenceRepo;
    late MockEventRepository eventRepo;
    late MockPaymentRepository paymentRepo;
    late MockMemberRepository memberRepo;
    late MockHmacService hmacService;
    late MockSyncCoordinator syncCoordinator;
    late IClock clock;
    int invoiceCounter = 0;

    setUp(() {
      invoiceCounter = 0;
      sequenceRepo = MockSequenceRepository();
      eventRepo = MockEventRepository();
      paymentRepo = MockPaymentRepository();
      memberRepo = MockMemberRepository();
      hmacService = MockHmacService();
      syncCoordinator = MockSyncCoordinator();
      clock = FrozenClock(DateTime(2026, 4, 16));

      when(() => hmacService.getInstallationId()).thenAnswer((_) async => 'test-device');
      when(() => eventRepo.watch()).thenAnswer((_) => const Stream.empty());
      when(() => paymentRepo.getAllPayments()).thenAnswer((_) async => []);
      when(() => eventRepo.getAll()).thenAnswer((_) async => []);
      when(() => syncCoordinator.triggerSync()).thenReturn(null);
    });

    test('Concurrent payments produce unique, sequential invoice numbers', () async {
      when(() => sequenceRepo.getNextInvoiceNumber(any())).thenAnswer((invocation) async {
        invoiceCounter++;
        return 'INV-2026-${invoiceCounter.toString().padLeft(4, "0")}';
      });
      when(() => memberRepo.getMember(any())).thenAnswer((_) async => null);
      when(() => eventRepo.persist(any())).thenAnswer((_) async {});
      when(() => paymentRepo.upsertPayment(any())).thenAnswer((_) async {});

      // Fix: Mock getPayment to return a payment with the ACTUAL invoice number from recordMemberPayment flow
      // In recordMemberPayment, it creates a Payment object and THEN calls getPayment(payment.id).
      // We should return that same payment but we don't have access to it easily in when().
      // However, recordMemberPayment returns signed ?? payment.
      // If we return null from getPayment, it returns the local 'payment' object which HAS the invoice number.
      when(() => paymentRepo.getPayment(any())).thenAnswer((_) async => null);

      final notifier = PaymentNotifier(
        sequenceRepo,
        eventRepo,
        paymentRepo,
        memberRepo,
        clock,
        hmacService,
        syncCoordinator,
      );

      final plan = Plan(
        id: 'p1',
        name: 'Plan 1',
        durationMonths: 1,
        components: [PlanComponent(id: 'c1', name: 'Base', price: 100)],
      );

      final results = await Future.wait([
        notifier.recordMemberPayment(memberId: 'm1', plan: plan, method: 'Cash'),
        notifier.recordMemberPayment(memberId: 'm2', plan: plan, method: 'Cash'),
        notifier.recordMemberPayment(memberId: 'm3', plan: plan, method: 'Cash'),
        notifier.recordMemberPayment(memberId: 'm4', plan: plan, method: 'Cash'),
        notifier.recordMemberPayment(memberId: 'm5', plan: plan, method: 'Cash'),
      ]);

      final invoiceNumbers = results.map((p) => p.invoiceNumber).toList();
      print('Invoice numbers: $invoiceNumbers');
      expect(invoiceNumbers.toSet().length, 5);
      invoiceNumbers.sort();
      expect(invoiceNumbers, [
        'INV-2026-0001',
        'INV-2026-0002',
        'INV-2026-0003',
        'INV-2026-0004',
        'INV-2026-0005',
      ]);
    });
  });
}
