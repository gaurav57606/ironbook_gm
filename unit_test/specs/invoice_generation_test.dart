import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:ironbook_gm/core/services/invoice_service.dart';
import 'package:ironbook_gm/core/data/local/models/invoice_sequence.dart';
import 'package:ironbook_gm/shared/utils/clock.dart';

void main() {
  group('Invoice Generation Logic (TC-UNIT-03)', () {
    late InvoiceService service;
    late Box<InvoiceSequence> box;

    setUp(() async {
      Hive.init('.');
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(InvoiceSequenceAdapter());
      }
      box = await Hive.openBox<InvoiceSequence>('invoice_seq');
      service = InvoiceService(box, SystemClock());
    });

    tearDown(() async {
      await box.clear();
      await box.close();
    });

    test('Should increment invoice number sequentially', () async {
      final inv1 = await service.next();
      final inv2 = await service.next();
      final inv3 = await service.next();

      final currentYear = DateTime.now().year;
      expect(inv1, 'INV-$currentYear-0001');
      expect(inv2, 'INV-$currentYear-0002');
      expect(inv3, 'INV-$currentYear-0003');
    });

    test('Should persist sequence in Hive', () async {
      await service.next();
      await service.next();
      
      final seq = box.get('active_seq');
      expect(seq?.nextNumber, 3);
    });

    test('Should reset sequence on manual reset', () async {
      await service.next();
      await service.reset(2027);
      
      final inv = await service.next();
      expect(inv, 'INV-2027-0001');
    });

    test('Should handle large sequences with correct padding', () async {
      final seq = box.get('active_seq') ?? InvoiceSequence(prefix: 'INV-2026-', nextNumber: 999);
      await box.put('active_seq', seq.copyWith(nextNumber: 999));
      
      final inv999 = await service.next();
      final inv1000 = await service.next();
      
      expect(inv999, contains('0999'));
      expect(inv1000, contains('1000'));
    });
  });
}

extension on InvoiceSequence {
  InvoiceSequence copyWith({int? nextNumber}) {
    return InvoiceSequence(
      prefix: prefix,
      nextNumber: nextNumber ?? this.nextNumber,
    );
  }
}



