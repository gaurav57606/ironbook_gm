import 'package:flutter_test/flutter_test.dart';
import 'package:ironbook_gm/core/utils/date_utils.dart';
import 'package:ironbook_gm/providers/payment_provider.dart';
import 'package:ironbook_gm/data/local/models/payment_model.dart';
import 'package:ironbook_gm/data/local/models/invoice_sequence.dart';
import 'package:ironbook_gm/data/local/models/plan_model.dart';
import 'package:ironbook_gm/data/repositories/event_repository.dart';
import 'package:ironbook_gm/core/utils/clock.dart';
import 'package:ironbook_gm/data/local/adapters/manual_adapters.dart' hide InvoiceSequenceAdapter;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ironbook_gm/core/services/hmac_service.dart';
import 'package:ironbook_gm/data/local/models/member_snapshot_model.dart';
import 'package:ironbook_gm/data/local/models/domain_event_model.dart';
import 'dart:io';

class MockEventRepository extends Mock implements IEventRepository {
  @override
  Future<void> persist(dynamic event) async {}

  @override
  Future<List<DomainEvent>> getAll() async => [];

  @override
  Stream<DomainEvent> watch() => const Stream.empty();
}

class MockHmacService extends Mock implements HmacService {
  @override
  Future<String> getInstallationId() async => 'test-device';
}

void main() {
  group('AppDateUtils Tests', () {
    test('addMonths: handles month overflow (Jan 31 + 1m = Feb 28)', () {
      final start = DateTime(2023, 1, 31);
      final end = AppDateUtils.addMonths(start, 1);
      expect(end.month, 2);
      expect(end.day, 28);
    });

    test('addMonths: handles leap year (Feb 29, 2024 + 12m = Feb 28, 2025)', () {
      final start = DateTime(2024, 2, 29);
      final end = AppDateUtils.addMonths(start, 12);
      expect(end.year, 2025);
      expect(end.month, 2);
      expect(end.day, 28);
    });

    test('addMonths: normal addition', () {
      final start = DateTime(2023, 1, 15);
      final end = AppDateUtils.addMonths(start, 3);
      expect(end.month, 4);
      expect(end.day, 15);
    });
  });

  group('PaymentNotifier Atomic Indexing Tests', () {
    late Box<Payment> paymentBox;
    late Box<InvoiceSequence> sequenceBox;
    late MockEventRepository eventRepo;
    late MockHmacService hmacService;
    late IClock clock;

    setUp(() async {
      final tempDir = Directory.systemTemp.createTempSync();
      Hive.init(tempDir.path);
      
      if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PaymentAdapter());
      if (!Hive.isAdapterRegistered(12)) Hive.registerAdapter(InvoiceSequenceAdapter());
      if (!Hive.isAdapterRegistered(13)) Hive.registerAdapter(PlanComponentSnapshotAdapter());

      paymentBox = await Hive.openBox<Payment>('payments_test');
      sequenceBox = await Hive.openBox<InvoiceSequence>('sequences_test');
      await Hive.openLazyBox<MemberSnapshot>('snapshots');
      eventRepo = MockEventRepository();
      hmacService = MockHmacService();
      clock = FrozenClock(DateTime(2026, 4, 16));
    });

    tearDown(() async {
      await Hive.close();
    });

    test('Concurrent payments produce unique, sequential invoice numbers', () async {
      final notifier = PaymentNotifier(
        paymentBox,
        sequenceBox,
        eventRepo,
        clock,
        hmacService,
      );

      final plan = Plan(id: 'p1', name: 'Plan 1', durationMonths: 1, components: []);

      // Trigger 10 "concurrent" payments
      final results = await Future.wait([
        notifier.recordMemberPayment(memberId: 'm1', plan: plan, method: 'Cash'),
        notifier.recordMemberPayment(memberId: 'm2', plan: plan, method: 'Cash'),
        notifier.recordMemberPayment(memberId: 'm3', plan: plan, method: 'Cash'),
        notifier.recordMemberPayment(memberId: 'm4', plan: plan, method: 'Cash'),
        notifier.recordMemberPayment(memberId: 'm5', plan: plan, method: 'Cash'),
      ]);

      final invoiceNumbers = results.map((p) => p.invoiceNumber).toList();
      
      // Verify uniqueness
      expect(invoiceNumbers.toSet().length, 5);
      
      // Verify sequence (Note: since they are concurrent but locked, they should be 1-5 in some order)
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
